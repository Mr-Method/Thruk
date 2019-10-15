package Thruk::Utils::CLI::Cluster;

=head1 NAME

Thruk::Utils::CLI::Cluster - Cluster CLI module

=head1 DESCRIPTION

Show information about a Thruk cluster

=head1 SYNOPSIS

  Usage: thruk [globaloptions] cluster <cmd>

=head1 OPTIONS

=over 4

=item B<help>

    print help and exit

=item B<cmd>

    available commands are:

    - status       displays status of the cluster

=back

=cut

use warnings;
use strict;

our $skip_backends = 1;

##############################################

=head1 METHODS

=head2 cmd

    cmd([ $options ])

=cut
sub cmd {
    my($c, $action, $commandoptions) = @_;
    $c->stats->profile(begin => "_cmd_cluster($action)");

    if(scalar @{$commandoptions} == 0) {
        return(Thruk::Utils::CLI::get_submodule_help(__PACKAGE__));
    }
    my $mode = shift @{$commandoptions};

    if(!$c->cluster->is_clustered()) {
        return("cluster disabled - this is a single node installation and not clustered\n", 3);
    }

    $c->cluster->load_statefile();

    my($output, $rc) = ("", 0);
    if($mode eq 'status') {
        my($total, $ok) = (0, 0);
        $output .= sprintf("%-12s %-25s %-40s %-17s %-10s\n", "STATUS", "HOSTNAME", "URL", "RESPONSE TIME", "VERSION");
        $output .= ('-' x 110)."\n";
        for my $n (@{$c->cluster->{'nodes'}}) {
            $total++;
            my $status = '';
            if($c->cluster->is_it_me($n)) {
                $status = 'OK';
                $ok++;
            }
            elsif($n->{'last_contact'} <= 0) {
                $status = 'WAITING';
            } elsif(time() - $n->{'last_contact'} < $c->config->{'cluster_node_stale_timeout'}) {
                $status = 'OK';
                $ok++;
            } else {
                $status = 'DOWN';
            }
            $output .= sprintf("%-12s %-25s %-40s %-17s %-10s\n",
                $status,
                $n->{'hostname'},
                $n->{'node_url'},
                $n->{'response_time'} ? sprintf("%.2fs", $n->{'response_time'}) : '',
                $n->{'branch'} ? $n->{'version'}.' - '.$n->{'branch'} : $n->{'version'},
            );
        }
        $output .= ('-' x 110)."\n";
        $output .= sprintf("%d/%d nodes online\n", $ok, $total);
    } else {
        return(Thruk::Utils::CLI::get_submodule_help(__PACKAGE__));
    }

    $c->stats->profile(end => "_cmd_cluster($action)");
    return($output, $rc);
}

##############################################

=head1 EXAMPLES

Show cluster status

  %> thruk cluster status

=cut

##############################################

1;