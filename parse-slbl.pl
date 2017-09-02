#!/bin/env perl

use strict;
use warnings;

my $infh;
if ($ARGV[0]) {
	open ($infh, '<:encoding(UTF-8)', $ARGV[0]) || die "Could not open ".$ARGV[0].".";	
} else {
	print "\nUsage: $0 <filename.csv>\n";
	exit 1;
}

my $output_files = [];
{
	no warnings qw/uninitialized/; # Hide warnings if there is no extension... (kludge)
	($output_files->[0] = $ARGV[0]) =~ s/([\w\-\_]*)(\..*)?/$1-by_domain-with_emails$2/;
	($output_files->[1] = $ARGV[0]) =~ s/([\w\-\_]*)(\..*)?/$1-by_full-addrs-with_emails$2/;	
}


my $domain_lists = {};
my $full_addrs_list = {};

while (my $row = <$infh>) {
	# Filter out comments, spaces, and line endings.
	$row =~ s/\#.*//g;
	$row =~ s/ //g;
	$row =~ s/\r\n|\n|\r//g;

	if (length($row) > 1) {
		# Parse out the individual fields for a given line in the file.
		my @fields = split(',', $row);

		# Shift off the first two elements and store them
		# so that we can use them later. Also leaves us the 
		# rest of the safe / block list as the @fields array.
		map { $_ = shift @fields } my ($email, $list);

		# Keep a global count of domains on the individual safe / block domain_lists.
		map { push @{$full_addrs_list->{$list}->{$_}}, $email } @fields;

		# For that user, map out what domains are in their safe / block list.
		map { s/.*@(.*)/$1/; } @fields;

		# Keep a global count of domains on the individual safe / block domain_lists.
		map { push @{$domain_lists->{$list}->{$_}}, $email } @fields;
	}
}
close $infh;

foreach my $i (0.. scalar @{$output_files}) {
	open (my $outfh, '>:encoding(UTF-8)', $output_files->[$i]) || die "Could not open ". $output_files->[$i] ." for writing.";
	if ($i eq 0) {
		for my $list (keys %$domain_lists) {
			for my $domain (keys %{$domain_lists->{$list}}) {
				for my $email (@{$domain_lists->{$list}->{$domain}}) {
					print $outfh "$list, $domain, $email\n";
				}
			}
		}
	}
	if ($i eq 1) {
		for my $list (keys %$full_addrs_list) {
			for my $domain (keys %{$full_addrs_list->{$list}}) {
				for my $email (@{$full_addrs_list->{$list}->{$domain}}) {
					print $outfh "$list, $domain, $email\n";
				}
			}
		}
	}
	close $outfh;
}

