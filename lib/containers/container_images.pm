# SUSE's openQA tests
#
# Copyright © 2020 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Functionality concerning the testing of container images
# Maintainer: George Gkioulis <ggkioulis@suse.de>

package containers::container_images;

use base Exporter;
use Exporter;

use base "consoletest";
use testapi;
use utils;
use strict;
use warnings;
use version_utils;

our @EXPORT = qw(build_container_image build_with_zypper_docker build_with_sle2docker test_opensuse_based_image exec_on_container);

# Build any container image using a basic Dockerfile
sub build_container_image {
    my %args    = @_;
    my $image   = $args{image};
    my $runtime = $args{runtime};

    die 'Argument $image not provided!'   unless $image;
    die 'Argument $runtime not provided!' unless $runtime;

    my $dir = "/root/sle_base_image/docker_build";

    record_info("Building $image", "Building $image using $runtime");

    assert_script_run("mkdir -p $dir");
    assert_script_run("cd $dir");

    # Create basic Dockerfile
    assert_script_run("echo -e 'FROM $image\nENV WORLD_VAR Arda' > Dockerfile");

    # Build the image
    assert_script_run("$runtime build -t dockerfile_derived .");

    assert_script_run("$runtime run --entrypoint 'printenv' dockerfile_derived WORLD_VAR | grep Arda");
    assert_script_run("$runtime images");
}

# Build a sle container image using zypper_docker
sub build_with_zypper_docker {
    my %args          = @_;
    my $image         = $args{image};
    my $runtime       = $args{runtime};
    my $derived_image = "zypper_docker_derived";

    my $distri  = $args{distri}  //= get_required_var("DISTRI");
    my $version = $args{version} //= get_required_var("VERSION");

    die 'Argument $image not provided!'   unless $image;
    die 'Argument $runtime not provided!' unless $runtime;

    my ($host_version,  $host_sp,  $host_id)  = get_os_release();
    my ($image_version, $image_sp, $image_id) = get_os_release("$runtime run --rm $image");

    # The zypper-docker works only on openSUSE or on SLE based image on SLE host
    unless (($host_id =~ 'sles' && $image_id =~ 'sles') || $image_id =~ 'opensuse') {
        record_info 'The zypper-docker only works for openSUSE based images and SLE based images on SLE host.';
        return;
    }

    # zypper docker can only update image if version is same as SUT
    if ($distri eq 'sle') {
        my $pretty_version = $version =~ s/-SP/ SP/r;
        my $betaversion    = get_var('BETA') ? '\s\([^)]+\)' : '';
        validate_script_output("$runtime container run --entrypoint '/bin/bash' --rm $image -c 'cat /etc/os-release'", sub { /PRETTY_NAME="SUSE Linux Enterprise Server ${pretty_version}${betaversion}"/ });
    }
    else {
        $version =~ s/^Jump://i;
        validate_script_output qq{$runtime container run --entrypoint '/bin/bash' --rm $image -c 'cat /etc/os-release'}, sub { /PRETTY_NAME="openSUSE (Leap )?${version}.*"/ };
    }

    zypper_call("in zypper-docker") if (script_run("which zypper-docker") != 0);
    assert_script_run("zypper-docker list-updates $image",      240);
    assert_script_run("zypper-docker up $image $derived_image", timeout => 160);

    # If zypper-docker list-updates lists no updates then derived image was successfully updated
    assert_script_run("zypper-docker list-updates $derived_image | grep 'No updates found'", 240);

    my $local_images_list = script_output("$runtime image ls");
    die("$runtime $derived_image not found") unless ($local_images_list =~ $derived_image);

    record_info("Testing derived");
    test_opensuse_based_image(image => $derived_image, runtime => $runtime);
}

# Testing openSUSE based images
sub test_opensuse_based_image {
    my %args    = @_;
    my $image   = $args{image};
    my $runtime = $args{runtime};

    my $distri  = $args{distri}  //= get_required_var("DISTRI");
    my $version = $args{version} //= get_required_var("VERSION");

    die 'Argument $image not provided!'   unless $image;
    die 'Argument $runtime not provided!' unless $runtime;
    record_info "os release";
    script_run "ls /etc/os-release";
    script_run "cat /etc/os-release";
    record_info "end os release ";
    my ($host_version,  $host_sp,  $host_id)  = get_os_release();
    my ($image_version, $image_sp, $image_id) = get_os_release("$runtime run --entrypoint '' $image");

    record_info "Host",  "Host has '$host_version', '$host_sp', '$host_id' in /etc/os-release";
    record_info "Image", "Image has '$image_version', '$image_sp', '$image_id' in /etc/os-release";

    $version = 'Tumbleweed' if ($version =~ /^Staging:/);

    if ($image_id =~ 'sles') {
        my $pretty_version = $version =~ s/-SP/ SP/r;
        my $betaversion    = get_var('BETA') ? '\s\([^)]+\)' : '';
        record_info "Validating", "Validating That $image has $pretty_version on /etc/os-release";
        validate_script_output("$runtime container run --entrypoint '/bin/bash' --rm $image -c 'grep PRETTY_NAME /etc/os-release' | cut -d= -f2",
            sub { /"SUSE Linux Enterprise Server ${pretty_version}${betaversion}"/ });

        # SUSEConnect zypper service is supported only on SLE based image on SLE host
        if ($host_id =~ 'sles') {
            my $plugin = '/usr/lib/zypp/plugins/services/container-suseconnect-zypp';
            assert_script_run "$runtime container run --entrypoint '/bin/bash' --rm $image -c '$plugin -v'";
            script_run "$runtime container run --entrypoint '/bin/bash' --rm $image -c '$plugin lp'", 420;
            script_run "$runtime container run --entrypoint '/bin/bash' --rm $image -c '$plugin lm'", 420;
        } else {
            record_info "non-SLE host", "This host ($host_id) does not support zypper service";
        }
    } else {
        $version =~ s/^Jump://i;
        validate_script_output qq{$runtime container run --entrypoint '/bin/bash' --rm $image -c 'cat /etc/os-release'}, sub { /PRETTY_NAME="openSUSE (Leap )?${version}.*"/ };
    }

    # Zypper is supported only on openSUSE or on SLE based image on SLE host
    if (($host_id =~ 'sles' && $image_id =~ 'sles') || $image_id =~ 'opensuse') {
        # zypper lr
        assert_script_run("$runtime run --rm $image zypper lr -s", 120);
        # zypper ref
        assert_script_run("$runtime run --name refreshed $image sh -c 'zypper -v ref | grep \"All repositories have been refreshed\"'", 120);
        # Commit the image
        assert_script_run("$runtime commit refreshed refreshed-image", 120);
        # Remove it
        assert_script_run("$runtime rm refreshed", 120);
        # Verify the image works
        assert_script_run("$runtime run --rm refreshed-image sh -c 'zypper -v ref | grep \"All repositories have been refreshed\"'", 120);
    }
}

sub exec_on_container {
    my ($image, $runtime, $command, $timeout) = @_;
    $timeout //= 120;
    assert_script_run("$runtime run --rm $image $command", $timeout);
}

1;
