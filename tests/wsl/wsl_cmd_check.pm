# SUSE's openQA tests
#
# Copyright © 2012-2021 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# Summary: Validate WSL image from host
# Maintainer: qa-c <qa-c@suse.de>

use Mojo::Base qw(windowsbasetest);
use testapi qw(assert_and_click enter_cmd get_var autoinst_url check_screen match_has_tag);
use version_utils qw(is_sle is_opensuse);
use wsl qw(is_sut_reg);

my %expected = (
    provider => get_var('WSL2') ? 'microsoft' : '(wsl|kvm)',
    mount    => '/mnt/c'
);

sub run {
    my $self = shift;

    assert_and_click 'powershell-as-admin-window';
    enter_cmd 'exit';
    $self->open_powershell_as_admin();
    while (1) {
	check_screen 'bsod', 15;
	if (match_has_tag 'bsod') {
	    $self->wait_boot_windows;
	    $self->open_powershell_as_admin();
		my ($day, $month, $year) = (localtime)[3,4,5];
		my $datestr = sprintf "%04d-%02d-%02d", $year+1900, $month+1, $day;
		my $logs = $datestr . '_Eventlogs100.txt'; 
		$self->run_in_powershell(cmd => '$file = New-Item -Path "C:\\temp\\" -ItemType file -Name "' . $logs .'" -Force');
		$self->run_in_powershell(cmd => 'Get-EventLog -LogName System -EntryType Error -Newest 100 | format-table -wrap | out-file ' . $logs , timeout => 60);
		$self->run_in_powershell(cmd => 'Set-Location -Path c:\temp');
		$self->run_in_powershell(cmd => 'wsl curl --form upload=\@' . $logs .' --form upname=' . $logs . ' ' . autoinst_url("/uploadlog/$logs"));
	    my $minidump_dir ='';
	    $self->run_in_powershell(cmd => 'Set-Location -Path c:\\');
		if ($self->run_in_powershell(cmd => 'Test-Path -Path Window\\Minidump')) {
		    $self->run_in_powershell(cmd => 'wsl tar -xf minidump.tar Window\\Minidump');
		    $self->run_in_powershell(cmd => 'wsl curl --form upload=\@minidump.tar --form upname=minidump.tar '. autoinst_url("/uploadlog/minidump.tar"));
		}
	    $self->run_in_powershell(cmd => 'wsl cd $HOME');
	    
	}
    #$self->run_in_powershell(cmd => 'Set-Location C:\\Windows;');
    #upload_logs("PFRO.log");
    #$self->run_in_powershell(cmd => 'curl --form upload=\@PFRO.log --form upname=PFRO.log \"' . autoinst_url("/uploadlog/PFRO.log") . '\"');
    #$self->run_in_powershell(cmd => 'echo ' . autoinst_url("/uploadlog/"));

    # my ($day, $month, $year) = (localtime)[3,4,5];
    # my $datestr = sprintf "%04d-%02d-%02d", $year+1900, $month+1, $day;
    # my $logs = $datestr . '_Eventlogs100.txt';
   
    # $self->run_in_powershell(cmd => '$file = New-Item -Path "C:\\temp\\" -ItemType file -Name "' . $logs .'" -Force');

    # $self->run_in_powershell(cmd => 'Get-EventLog -LogName System -EntryType Error -Newest 100 | format-table -wrap | out-file '. $logs , timeout => 60);
    # $self->run_in_powershell(cmd => 'Set-Location -Path c:\temp');
    # $self->run_in_powershell(cmd => 'wsl curl --form upload=\@' . $logs .' --form upname=' . $logs . ' ' . autoinst_url("/uploadlog/$logs"));
        
    $self->run_in_powershell(cmd => 'wsl --list --verbose',                                                     timeout => 60);
    $self->run_in_powershell(cmd => "wsl mount | Select-String -Pattern $expected{mount}",                      timeout => 60);
    $self->run_in_powershell(cmd => qq{wsl ls $expected{mount}},                                                timeout => 60);
    $self->run_in_powershell(cmd => qq/wsl systemd-detect-virt | Select-String -Pattern "$expected{provider}"/, timeout => 60);
    $self->run_in_powershell(cmd => 'wsl /bin/bash -c "dmesg | head -n 20"');
    $self->run_in_powershell(cmd => 'wsl env');
    $self->run_in_powershell(cmd => 'wsl locale', timeout => 60);
    $self->run_in_powershell(cmd => 'wsl date');
    if (is_opensuse || (is_sle && is_sut_reg)) {
        $self->run_in_powershell(cmd => 'wsl -u root zypper -q -n in python3', timeout => 120);
        $self->run_in_powershell(cmd => q{wsl python3 -c "print('Hello from Python living in WSL')"});
    }
	 
    $self->run_in_powershell(cmd => 'wsl --shutdown',       timeout => 60);
	    $self->run_in_powershell(cmd => 'wsl --list --verbose', timeout => 60);
	       last;
	
    }
}

sub post_fail_hook {
    my ($self) = @_;
    my $minidump_dir ='';
    if ($self->run_in_powershell(cmd => 'Set-Location -Path Window\\Minidump')) {
	$self->run_in_powershell(cmd => 'wsl tar -xf minidump.tar Window\\Minidump');
	$self->run_in_powershell(cmd => 'wsl curl --form upload=\@minidump.tar --form upname=minidump.tar '. autoinst_url("/uploadlog/minidump.tar"));
    }
}
1;
