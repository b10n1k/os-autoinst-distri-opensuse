# SUSE's openQA tests
#
# Copyright © 2016 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Summary: Test if login manager is usable with many users
#   This test checks if many users make the login manager hard to use
#   i.e. if it takes more than one click to access the username text field
# Maintainer: Dominik Heidler <dheidler@suse.de>
# Tags: poo#9694

use base "x11test";
use strict;
use testapi;

sub ensure_multi_user_target {
    type_string "systemctl isolate multi-user.target\n";
    reset_consoles;
    wait_still_screen 10;
    # isolating multi-user.target logs us out
    select_console 'root-console';
}

sub ensure_graphical_target {
    type_string "systemctl isolate graphical.target\n";
    reset_consoles;
}

sub restart_x11 {
    ensure_multi_user_target;
    ensure_graphical_target;
}

sub run() {

    my $users_to_create = 100;
    my $encrypted_password = crypt($password, "abcsalt");

    # login
    select_console 'root-console';

    # disable autologin
    script_run "sed -i.bak '/^DISPLAYMANAGER_AUTOLOGIN=/s/=.*/=\"\"/' /etc/sysconfig/displaymanager";
    assert_script_run "~$username/data/create_users $users_to_create \"$encrypted_password\"";
    restart_x11;

    assert_screen "multi_users_dm";

    # restore previous config
    select_console 'root-console';
    script_run "mv /etc/sysconfig/displaymanager.bak /etc/sysconfig/displaymanager";
    assert_script_run "~$username/data/delete_users $users_to_create";
    script_run "clear";
    restart_x11;
    # after restart of X11 give the desktop a bit more time to show up to
    # prevent the post_run_hook to fail being too impatient
    assert_screen 'generic-desktop', 600;
}

1;
# vim: set sw=4 et:
