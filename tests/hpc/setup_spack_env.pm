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
use utils;
#use lockapi;

sub run ($self) {
    my $mpi = $self->get_mpi();
    $self->prepare_spack_env($mpi);

    record_info 'spack info', script_output "spack info $mpi";
}

sub post_run_hook ($self) {}
1;
