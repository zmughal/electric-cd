package App::Electric::CD;

use strict;
use warnings;

use App::Electric::Window;
use Log::Log4perl;

my $log_conf = q/
	log4perl.category = INFO, Logfile

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


#sub main {
#        my $key;
#        my $ticks = 0;
#        do {
#                $key = getch;
#                draw_prompt();
#        } while( !defined($key) || $key ne 'q');
#}
#
#sub draw_prompt {
#        my $prompt = $win{prompt};
#        #$prompt->box('|', '-');
#        $prompt->border(border_ACS());
#        $prompt->addstr(1, 1, "Abc");
#        $prompt->refresh;
#}

sub run {
	#Log::Log4perl::init( \$log_conf );
	Log::Log4perl::init( \"" );
	die ("Need output") unless defined (my $output = shift @ARGV);
	my $logger = Log::Log4perl::get_logger("main");
	$logger->info("Starting window");
	App::Electric::Window->new(output => $output)->mainloop();
}

1;
