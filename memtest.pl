#!/usr/bin/perl
use strict;
use warnings;
use Log::Log4perl;
use Try::Tiny;

# Initialize logger
Log::Log4perl->init(\ <<'EOT');
log4perl.logger = INFO, LOGFILE, Screen
log4perl.appender.LOGFILE = Log::Log4perl::Appender::File
log4perl.appender.LOGFILE.filename = script.log
log4perl.appender.LOGFILE.mode = append
log4perl.appender.LOGFILE.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.LOGFILE.layout.ConversionPattern = %d %p %m %n

log4perl.appender.Screen = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr = 0
log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %p %m %n
EOT

my $logger = Log::Log4perl->get_logger();

# Define the MemoryManager class
package MemoryManager;

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub find_memto_occupy {
    my ($self, $pc) = @_;
    
    $logger->info("Attempting to find memory to occupy based on percentage: $pc%");
    
    if ($pc > 100 || $pc < 1) {
        $logger->error("Invalid percentage value: $pc");
        die "Invalid percentage given: $pc\n";
    }

    my $memtotal;

    try {
        open my $meminfo, '<', '/proc/meminfo' or die "Unable to open /proc/meminfo: $!\n";
        while (<$meminfo>) {
            if (/^MemTotal:\s+(\d+)\s+/) {
                $memtotal = $1;
                last;
            }
        }
        close $meminfo;

        unless (defined $memtotal) {
            $logger->error("Failed to retrieve total memory from /proc/meminfo.");
            die "Unable to retrieve total memory from /proc/meminfo\n";
        }

        my $mem_mb = int((($memtotal * $pc) / 100) / 1024);  # Convert from KB to MB
        $logger->info("Memory calculated to occupy: $mem_mb MB");
        return $mem_mb;

    } catch {
        $logger->error("Error finding memory to occupy: $_");
        die $_;
    };
}

sub allocate_memory {
    my ($self, $mb) = @_;
    $logger->info("Allocating $mb MB of memory.");

    try {
        my $bytes = $mb * 1024 * 1024;
        
        # Allocate memory
        open my $memfile, '>', \my $memory or die "Failed to allocate memory: $!\n";
        seek($memfile, $bytes - 1, 0) or die "Seek failed: $!";
        print $memfile chr(0);
        close $memfile;

        $logger->info("Successfully allocated $mb MB of memory.");
        return $memory;  # Keep reference to avoid memory being freed

    } catch {
        $logger->error("Memory allocation failed: $_");
        die $_;
    };
}

sub release_memory {
    my ($self, $memory_ref) = @_;
    undef $$memory_ref;  # Release memory
    $logger->info("Memory released by user.");
}

# Main script logic
package main;

{
    my $num = shift @ARGV;
    
    unless (defined $num && $num =~ /^\d+%?$/) {
        $logger->error("Invalid usage. Argument not provided or incorrect.");
        die "Usage: $0 <occupy MB or percentage>\nEx: $0 100 (occupy 100 MB) or $0 50% (occupy 50% of memory)\n";
    }

    $logger->info("Script started with argument: $num");

    try {
        my $mem_manager = MemoryManager->new();
        my $mb;

        if ($num =~ /^(\d+)%$/) {
            my $pc = $1;
            $mb = $mem_manager->find_memto_occupy($pc);
        } else {
            $mb = $num;
        }

        die "Memory to occupy must be at least 1 MB\n" if $mb < 1;

        my $memory = $mem_manager->allocate_memory($mb);

        print "$mb MB of memory is occupied. Press ENTER to release: ";
        <STDIN>;

        $mem_manager->release_memory(\$memory);
        print "Memory released\n";

    } catch {
        $logger->error("An error occurred: $_");
        die $_;
    };
}
