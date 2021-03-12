perl -e '

use 5.016;
use warnings;
use File::Basename;
use File::Copy;
use Config;

my $NODE_SRC_WIN32 = "https://nodejs.org/dist/v9.11.2/node-v9.11.2-win-x86.zip";
my $NODE_SRC_WIN64 = "https://nodejs.org/dist/v9.11.2/node-v9.11.2-win-x64.zip";

sub is_windows_32bit {
	return index($ENV{"PROCESSOR_ARCHITECTURE"}, "x86") >= 0;
}

sub is_mingw() {
    my $msystem = exists $ENV{"MSYSTEM"} ? $ENV{"MSYSTEM"} : "";
    if (($msystem eq "MINGW64") or ($msystem eq "MINGW32") or ($msystem eq "MSYS")) {
        return 1;
    }
    return 0;
}

sub require_command {
    my $cmd = shift;
    my $test = "which " . $cmd;
    if (qx{$test} eq "") {
        die("[$cmd] command - not found.");
    }
}

sub request_useragent {
    return "Mozilla/5.0 (X11; Linux x86_64; rv:66.0) Gecko/20100101 Firefox/66.0";
}

sub ziparchive_extract {
    require_command("unzip");

	my ($src, $dest) = @_;
	my $result = "";
	my $cmd = "unzip -o \"$src\" -d \"$dest\"";
	$result = qx{$cmd};
	return $result;
}

sub request_get {
    require_command("curl");

    my ($url, $outfile) = @_;
    my $result = "";
    my $cmd = "curl -L \"$url\""
        . " -A \"" . request_useragent() . "\"";
    if ($outfile && ($outfile ne "")) {
        $cmd .= " -o \"$outfile\"";
    }
    $result = qx{$cmd};
    return $result;
}

my $srcUrl;
if (!is_mingw()) {
	die("Run this script from Git Bash -> https://gitforwindows.org/");
}
if (is_windows_32bit()) {
	$srcUrl = $NODE_SRC_WIN32;
} else {
	$srcUrl = $NODE_SRC_WIN64;
}

say "Install Bitrix CLI";

my $homeBin = $ENV{"HOME"} . "/bin";
if (!-d $homeBin) {
    mkdir($homeBin);
}
my $pathNodeBitrix = $homeBin . "/node_bitrix";
if (-d $pathNodeBitrix) {
	say "Remove $pathNodeBitrix ...";
    system("rm -Rf \"$pathNodeBitrix\"");
}

say "Loading $srcUrl...";
my $outputFile = $homeBin . "/" . basename($srcUrl);
my $outputDir = $homeBin . "/" . basename($srcUrl, ".zip");
request_get($srcUrl, $outputFile);
chdir($homeBin);
ziparchive_extract($outputFile, "./");
if (-f $outputFile) {
	unlink($outputFile);
}
if (-d $outputDir) {
	rename($outputDir, $pathNodeBitrix);
}

$ENV{"PATH"} = $pathNodeBitrix . ":" . $ENV{"PATH"};
system($pathNodeBitrix . "/npm install -g \@bitrix/cli");

'