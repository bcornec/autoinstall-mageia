#!/usr/bin/perl -w
#
use strict;
use Getopt::Long;

sub usage {
	print "Syntax: build-vagrant.pl [-t (sucuk|ecosse|rabbit|duvel|fiona)][-k]\n";
	print "\n";
	print "where you can give the type of system to build with the -t option\n";
	print "\n";
	print "If you want to regenerate admin user ssh keys, please specify the -k option\n";
	exit(-1);
}

my $mgatype = undef;
my $mgauser = "mgaadmin";
my $localnet = "mganet.local";
my $help;
my $genkeys;
# Automate Mageia systems creation
my %machines = (
	'sucuk' => "sucuk9",
	'ecosse' => "ecosse9",
	'rabbit' => "rabbit9",
	'duvel' => "duvel9",
	'fiona' => "fiona9",
);
my $machines = \%machines;

GetOptions("type|t=s" => \$mgatype,
	   "help|h" => \$help,
	   "gen-keys|k" => \$genkeys,
);

usage() if ($help || defined $ARGV[0]); 


# Manages the private network for machines and DHCP/DNS setup
# TODO: managing this depends on hypervisor type
my $mganet = `sudo virsh net-list --name`;
if ($mganet =~ /^vagrant-libvirt$/) {
	system("sudo virsh net-start --network vagrant-libvirt");
}
if ($mganet =~ /^mganet$/) {
	system("sudo virsh net-define mganet.xml");
	system("sudo virsh net-start --network mganet");
}

my @mtypes = ();
if (not defined $mgatype) {
	@mtypes = sort keys %machines;
} else {
	@mtypes = ($mgatype);
}

my $h = \%machines;
foreach my $m (@mtypes) {
	print "Stopping vagrant machine $h->{$m}\n";
	system("vagrant halt $h->{$m}");
	print "Starting vagrant machine $h->{$m}\n";
	system("vagrant up $h->{$m}");
	print "Getting IP address for vagrant machine $h->{$m}\n";
	open(CMD,"vagrant ssh-config $h->{$m} |") || die "Unable to execute vagrant ssh-config $h->{$m}";
	my $srvip = "";
	my $void;
	while (<CMD>) {
		next if ($_ !~ /HostName/);
		chomp($_);
		$srvip = $_;
		$srvip =~ s/\s+HostName\s+([0-9.]+)\s*/$1/;
		($void,$void,$srvip) = split(/ +/,$_);
		last;
	}
	print "Got $srvip\n";
	print "Installing vagrant machine $h->{$m}\n";
	my $kk = "";
	$kk = "-k" if ($genkeys);
	system("vagrant ssh $h->{$m} -c \"sudo /vagrant/install.sh -t $m -i $srvip -g production -u $mgauser $kk\"");
}
