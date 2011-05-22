package App::Electric::CD;

use strict;
use warnings;

use App::Electric::Window;
use Log::Log4perl;

my $log_file = "$ENV{HOME}/.ecd_debug.log";
#my $log_file = '/dev/null';
#my $level = "INFO";
my $level = "OFF";

my $log_conf_debug = qq/
	log4perl.category = INFO, Logfile

	log4perl.appender.Logfile = Log::Log4perl::Appender::File
	log4perl.appender.Logfile.filename = $log_file
	log4perl.appender.Logfile.mode = write
	log4perl.appender.Logfile.create_at_logtime = 1
	log4perl.appender.Logfile.layout = Log::Log4perl::Layout::PatternLayout
	log4perl.appender.Logfile.layout.ConversionPattern = %d %p> %m (%M)%n

	log4perl.logger.main = $level
	log4perl.logger.Window = $level
	log4perl.logger.Component = $level
	log4perl.logger.HManager = $level
	log4perl.logger.EditingComponent = $level
	log4perl.logger.ListComponent = $level

	log4perl.threshold = OFF
/;

sub run {
	Log::Log4perl::init( \$log_conf_debug );
	die ("Need output") unless defined (my $output = shift @ARGV);
	my $logger = Log::Log4perl::get_logger("main");
	$logger->info("Starting window");
	App::Electric::Window->new(output => $output)->mainloop();
}

1;
