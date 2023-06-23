# SUSE's openQA tests
#
# Copyright SUSE LLC
# SPDX-License-Identifier: FSFAP
# Summary: HPC_Module: Client nodes of a cluster with Spack
# Maintainer: Kernel QE <kernel-qa@suse.de>

use Mojo::Base qw(hpcbase hpc::utils), -signatures;
use testapi;

sub run ($self) {
    my %exports_path = (bin => '/home/bernhard/bin');
    $self->mount_nfs_exports(\%exports_path);
}

1;
