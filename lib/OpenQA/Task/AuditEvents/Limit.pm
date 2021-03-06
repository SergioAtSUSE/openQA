# Copyright (C) 2019 SUSE LLC
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

package OpenQA::Task::AuditEvents::Limit;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app) = @_;
    $app->minion->add_task(limit_audit_events => sub { _limit($app, @_) });
}

sub _limit {
    my ($app, $job) = @_;

    # prevent multiple limit_audit_events tasks to run in parallel
    return $job->finish('Previous limit_audit_events job is still active')
      unless my $guard = $app->minion->guard('limit_audit_events_task', 86400);

    # prevent multiple limit_* tasks to run in parallel
    return $job->retry({delay => 60})
      unless my $limit_guard = $app->minion->guard('limit_tasks', 86400);

    $app->schema->resultset('AuditEvents')->delete_entries_exceeding_storage_duration;
}

1;
