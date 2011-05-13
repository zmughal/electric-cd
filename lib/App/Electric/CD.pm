package App::Electric::CD;

use strict;
use warnings;

use App::Electric::Window;
use Log::Log4perl;

#my $log_conf_debug = q/log4perl.category = INFO, Logfile/;
my $log_conf_debug = q/log4perl.category = ERROR/;
$log_conf_debug .= q/
	log4perl.appender.Logfile = Log::Log4perl::Appender::File
	log4perl.appender.Logfile.filename = debug.log
	log4perl.appender.Logfile.mode = write
	log4perl.appender.Logfile.layout = Log::Log4perl::Layout::PatternLayout
	log4perl.appender.Logfile.layout.ConversionPattern = %d %p> %m (%M)%n

	log4perl.logger.main = INFO
	log4perl.logger.Window = INFO
	log4perl.logger.Component = INFO
	log4perl.logger.HManager = INFO
	log4perl.logger.EditingComponent = INFO
	log4perl.logger.ListComponent = INFO
/;

sub run {
	Log::Log4perl::init( \$log_conf_debug );
	die ("Need output") unless defined (my $output = shift @ARGV);
	my $logger = Log::Log4perl::get_logger("main");
	$logger->info("Starting window");
	App::Electric::Window->new(output => $output)->mainloop();
}

1;
