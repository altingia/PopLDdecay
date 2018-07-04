#!/usr/bin/perl-w
use strict;

use Data::Dumper;
use Getopt::Long;

#############Befor  Start  , open the files ####################

sub usage
{
	print STDERR <<USAGE;
	2016-04-22       hewm\@genomics.cn

	Usage:		perl $0  -inFile  LDdecay.stat.gz  -output OUT

	Options
	-inFile    <s> :  Input PopLDDecay OutPut Stat File
	-inList    <s> :  Input FileList if multi-File of PopLDDecay OutPut Stat
	-output    <s> :  Output Figure File Prefix


	-bin1      <n> :  the size bin for mean r^2 of Short Dist[10]
	-bin2      <n> :  the size bin for mean r^2 of Long Dist [100]
	-break     <n> :  break point to distinguish Short or Long Dist[100]
	-maxX      <n> :  max X coordinate Dist to plot LDdecay[kb] [maxDist]
	-keepR         :  keep the R script for draw the LDdecay Fig
	-help          :  show this help
USAGE
}

my ($help,$inFile,$inList,$output,$bin1,$bin2,$break,$keepR,$maxX);


GetOptions(
	"help"=>\$help,
	"inFile:s"=>\$inFile,
	"inList:s"=>\$inList,
	"output:s"=>\$output,
	"bin1:s"=>\$bin1,
	"bin2:s"=>\$bin2,
	"keepR"=>\$keepR,
	"break:s"=>\$break,
	"maxX:s"=>\$maxX,
);

if( defined($help) || !defined($output))
{
	usage;
	exit ;
}
if( (!defined($inFile)) && (!defined($inList)))
{
	usage;
	exit ;
}

$bin1||=10;
$bin2||=100;
$break||=100;




open OA,">$output.bin" || die "output file can't open $!" ;

################ Do what you want to do #######################

my %hash_cout=();
my %hash_coutV2=();
my %hash_RR_sum=();
my %hash_D_sum=();
my $bin=$bin2 ;



my %Small_cout=();
my %Small_coutV2=();
my %Small_RR_sum=();
my %Small_D_sum=();
my $Small_bin=$bin1 ;

my $maxX_tmp=0;

if ( defined($inFile) )
{

	if  ($inFile =~s/\.gz$/\.gz/)
	{
		open AA,"gzip -cd  $inFile | "  || die "input file can't open $!" ;
	}
	else
	{
		open AA,"$inFile"  || die "input file can't open $!" ;
	}

	while (<AA>)
	{
		chomp  ;
		my @inf=split ;
		next if  ($_=~s/#/#/);
		if  ($inf[0]>$maxX_tmp)
		{
			$maxX_tmp=$inf[0];
		}
		if ($inf[0]>=$break)
		{
			$inf[0]=int($inf[0]/$bin);
			$hash_cout{$inf[0]}+=$inf[-1] ;
			$hash_coutV2{$inf[0]}+=$inf[-1] if  ($inf[-2] ne  "NA" );
			$hash_D_sum{$inf[0]}+=$inf[-2]  if  ($inf[-2] ne  "NA" );
			$hash_RR_sum{$inf[0]}+=$inf[-3];
		}
		else
		{
			$inf[0]=int($inf[0]/$Small_bin);
			$Small_cout{$inf[0]}+=$inf[-1] ;
			$Small_coutV2{$inf[0]}+=$inf[-1]  if  ($inf[-2] ne  "NA" );
			$Small_D_sum{$inf[0]}+=$inf[-2]   if  ($inf[-2] ne  "NA" );
			$Small_RR_sum{$inf[0]}+=$inf[-3];
		}
	}
	close AA ;
}





if ( defined($inList) )
{

	if  ($inList =~s/\.gz$/\.gz/)
	{
		open LIST,"gzip -cd  $inList | "  || die "input file can't open $!" ;
	}
	else
	{
		open LIST,"$inList"  || die "input file can't open $!" ;
	}

	while($_=<LIST>)
	{
		my $FileThis=$_; chomp $FileThis;

		if  ($FileThis =~s/\.gz$/\.gz/)
		{
			open BBC,"gzip -cd  $FileThis | "  || die "input file can't open $!" ;
		}
		else
		{
			open BBC,"$FileThis"  || die "input file can't open $!" ;
		}

		while (<BBC>)
		{
			chomp  ;
			my @inf=split ;
			next if  ($_=~s/#/#/);
			if  ($inf[0]>$maxX_tmp)
			{
				$maxX_tmp=$inf[0];
			}

			if ($inf[0]>=$break)
			{
				$inf[0]=int($inf[0]/$bin);
				$hash_cout{$inf[0]}+=$inf[-1] ;
				$hash_coutV2{$inf[0]}+=$inf[-1] if  ($inf[-2] ne  "NA" );
				$hash_D_sum{$inf[0]}+=$inf[-2] if  ($inf[-2] ne  "NA" );
				$hash_RR_sum{$inf[0]}+=$inf[-3];
			}
			else
			{
				$inf[0]=int($inf[0]/$Small_bin);
				$Small_cout{$inf[0]}+=$inf[-1] ;
				$Small_coutV2{$inf[0]}+=$inf[-1]  if  ($inf[-2] ne  "NA" ) ;
				$Small_D_sum{$inf[0]}+=$inf[-2] if  ($inf[-2] ne  "NA" );
				$Small_RR_sum{$inf[0]}+=$inf[-3];
			}

		}
		close BBC ;
	}
	close LIST ;

}

$maxX_tmp=int($maxX_tmp/1000);

$maxX||=$maxX_tmp;

print OA "#Dist\tMean_r^2\tMean_D'\tSum_r^2\tSum_D'\tNumberPairs\n";


foreach my $k (sort {$a<=>$b} keys %Small_cout)
{
	my $mean_R=$Small_RR_sum{$k}/$Small_cout{$k};
	
	if  (exists $Small_coutV2{$k})
	{
	my $mean_D=$Small_D_sum{$k}/$Small_coutV2{$k};
	print OA ($k+1)*$Small_bin,"\t$mean_R\t$mean_D\t$Small_RR_sum{$k}\t$Small_D_sum{$k}\t$Small_cout{$k}\n";
	}
	else
	{
	print OA ($k+1)*$Small_bin,"\t$mean_R\tNA\t$Small_RR_sum{$k}\tNA\t$Small_cout{$k}\n";
	}
}

foreach my $k (sort {$a<=>$b} keys %hash_cout)
{
	my $mean_R=$hash_RR_sum{$k}/$hash_cout{$k};
	if  (exists $hash_coutV2{$k})
	{
	my $mean_D=$hash_D_sum{$k}/$hash_coutV2{$k};
	print OA ($k+1)*$bin ,"\t$mean_R\t$mean_D\t$hash_RR_sum{$k}\t$hash_D_sum{$k}\t$hash_cout{$k}\n";
	}
	else
	{
	print OA ($k+1)*$bin ,"\t$mean_R\tNA\t$hash_RR_sum{$k}\tNA\t$hash_cout{$k}\n";
	}
}
close OA ;


my $R="/ifs4/BC_PUB/biosoft/pipeline/newblc/03.Soft_ALL/R-3.3.1/bin/Rscript";

if  ( !(-e $R) )
{
	$R=`which Rscript`;chomp $R;
}


my $Rshell=<<LOVE;
read.table("$output.bin")->data
pdf("$output.pdf")
plot(data[,1]/1000,data[,2],type="l",col="blue",main="LD decay",xlab="Distance(Kb)",xlim=c(0,$maxX),ylab=expression(r^{2}),bty="n")
dev.off()
png("$output.png")
plot(data[,1]/1000,data[,2],type="l",col="blue",main="LD decay",xlab="Distance(Kb)",xlim=c(0,$maxX),ylab=expression(r^{2}),bty="n")
dev.off()

LOVE

open TMP,">$output.r" || die "output file can't open $!" ;

print TMP $Rshell ;
close TMP;


if  ( !(-e $R) )
{
	print "Can't find the [ Rscript ] bin, You shoud install the R First,then:\n";
	print " $R  $output.r  \n";
	exit(1);
}




system (" $R  $output.r  ");

if  (  defined($keepR) )
{
	system ("echo  $R  $output.r  ");
}
else
{
	system ("rm -rf   $output.r ");
}


######################swiming in the sky and flying in the sea #############################


