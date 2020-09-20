# SUSE's openQA tests
#
# Copyright © 2020 SUSE LLC
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, see <http://www.gnu.org/licenses/>.

# Summary: Module to descrypt encrypted disk
# Maintainer: QA SLE YaST team <qa-sle-yast@suse.de>

use strict;
use warnings;
use base "installbasetest";
use utils;
use testapi;

sub run {
    assert_screen("encrypted-disk-password-prompt", 200);
    type_password;
    save_screenshot;
    assert_screen 'encrypted_disk-typed_password';
    send_key "ret";
}

1;

