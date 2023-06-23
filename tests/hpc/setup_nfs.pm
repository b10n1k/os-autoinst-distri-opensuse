# SUSE's openQA tests
#
# Copyright SUSE LLC
# SPDX-License-Identifier: FSFAP
# Summary: HPC_Module: Test Spack package installation and features
#
# Acts as the master node of the cluster to execute parallel executions
#
# Maintainer: Kernel QE <kernel-qa@suse.de>

use Mojo::Base qw(hpcbase hpc::utils), -signatures;
use testapi;

sub run ($self) {
    my %exports_path = (bin => '/home/bernhard/bin');
    $self->setup_nfs_server(\%exports_path);
}


sub post_run_hook ($self) {}

1;
