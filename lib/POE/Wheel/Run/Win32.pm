package POE::Wheel::Run::Win32;

#ABSTRACT: portably run blocking code and programs in subprocesses

use strict;
use base 'POE::Wheel::Run';
use vars qw($VERSION);
$VERSION = '0.18';

1;

=pod

=head1 SYNOPSIS

  #!/usr/bin/perl

  use warnings;
  use strict;

  use POE qw( Wheel::Run::Win32 );

  POE::Session->create(
    inline_states => {
      _start           => \&on_start,
      got_child_stdout => \&on_child_stdout,
      got_child_stderr => \&on_child_stderr,
      got_child_close  => \&on_child_close,
      got_child_signal => \&on_child_signal,
    }
  );

  POE::Kernel->run();
  exit 0;

  sub on_start {
    my $child = POE::Wheel::Run::Win32->new(
      Program => [ "/bin/ls", "-1", "/" ],
      StdoutEvent  => "got_child_stdout",
      StderrEvent  => "got_child_stderr",
      CloseEvent   => "got_child_close",
    );

    $_[KERNEL]->sig_child($child->PID, "got_child_signal");

    # Wheel events include the wheel's ID.
    $_[HEAP]{children_by_wid}{$child->ID} = $child;

    # Signal events include the process ID.
    $_[HEAP]{children_by_pid}{$child->PID} = $child;

    print(
      "Child pid ", $child->PID,
      " started as wheel ", $child->ID, ".\n"
    );
  }

  # Wheel event, including the wheel's ID.
  sub on_child_stdout {
    my ($stdout_line, $wheel_id) = @_[ARG0, ARG1];
    my $child = $_[HEAP]{children_by_wid}{$wheel_id};
    print "pid ", $child->PID, " STDOUT: $stdout_line\n";
  }

  # Wheel event, including the wheel's ID.
  sub on_child_stderr {
    my ($stderr_line, $wheel_id) = @_[ARG0, ARG1];
    my $child = $_[HEAP]{children_by_wid}{$wheel_id};
    print "pid ", $child->PID, " STDERR: $stderr_line\n";
  }

  # Wheel event, including the wheel's ID.
  sub on_child_close {
    my $wheel_id = $_[ARG0];
    my $child = delete $_[HEAP]{children_by_wid}{$wheel_id};

    # May have been reaped by on_child_signal().
    unless (defined $child) {
      print "wid $wheel_id closed all pipes.\n";
      return;
    }

    print "pid ", $child->PID, " closed all pipes.\n";
    delete $_[HEAP]{children_by_pid}{$child->PID};
  }

  sub on_child_signal {
    print "pid $_[ARG1] exited with status $_[ARG2].\n";
    my $child = delete $_[HEAP]{children_by_pid}{$_[ARG1]};

    # May have been reaped by on_child_close().
    return unless defined $child;

    delete $_[HEAP]{children_by_wid}{$child->ID};
  }

=head1 DESCRIPTION

POE::Wheel::Run::Win32 executes a program or block of code in a subprocess.
The parent process may exchange information with the child over the
child's STDIN, STDOUT and STDERR filehandles.

It is basically a shim around L<POE::Wheel::Run>, since all the code that
did live here has been now merged into that.

=head1 AUTHORS & COPYRIGHTS

Please see L<POE> for more information about authors and contributors.

=cut

# rocco // vim: ts=2 sw=2 expandtab
# TODO - Edit.
