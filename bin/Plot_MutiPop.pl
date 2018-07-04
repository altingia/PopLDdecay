#!/usr/bin/perl-w
use strict;

use Data::Dumper;
use Getopt::Long;

#############Befor  Start  , open the files ####################

sub usage
{
	print STDERR <<USAGE;
	2016-07-04       hewm\@genomics.cn

	Usage:		perl $0  -inList  LDdecayResult.list  -output OUT

	Options
	-inList    <s> :  Muti LDDecat Stat File of muti Pop.
					  Format:[FilePath  PopID]
	-output    <s> :  Output Figure File Prefix


	-bin1      <n> :  the size bin for mean r^2 of Short Dist[10]
	-bin2      <n> :  the size bin for mean r^2 of Long Dist [100]
	-break     <n> :  break point to distinguish Short or Long Dist[100] 
	-maxX      <n> :  max X coordinate Dist to plot LDdecay[kb] [maxDist]
	-keepR         :  keep the R script for draw the LDdecay Fig
	-help          :  show this help
USAGE
}

my ($help,$inList,$output,$bin1,$bin2,$break,$keepR,$maxX);


GetOptions(
	"help"=>\$help,
	"inList:s"=>\$inList,
	"output:s"=>\$output,
	"bin1:s"=>\$bin1,
	"bin2:s"=>\$bin2,
	"keepR"=>\$keepR,
	"break:s"=>\$break,
	"maxX:s"=>\$maxX,
);

if( defined($help) || (!defined($output))   ||  (!defined($inList)) )
{
	usage;
	exit ;
}


$bin1||=10;
$bin2||=100;
$break||=100;





################ Do what you want to do #######################

my $bin=$bin2 ;
my $Small_bin=$bin1 ;

my $maxX_tmp=0;
my $maxY_tmp=0;

my @PopIDAryy=();



if  ($inList =~s/\.gz$/\.gz/)
{
	open LIST,"gzip -cd  $inList | "  || die "input file can't open $!" ;
}
else
{
	open LIST,"$inList"  || die "input file can't open $!" ;
}

while(<LIST>)
{
	my $FileThis=$_;
	chomp $FileThis ;
	my @SplltPath=split /\s+/,$FileThis ;
	if ( $#SplltPath<1 )
	{
		print "FileList Format wrong, should be (Two columns) :\n";
		print "Stat.FilePath.stat.gz   PopulationIDA\n";
		exit(1);
	}

	my %hash_cout=();
	my %hash_coutV2=();
	my %hash_RR_sum=();
	my %hash_D_sum=();

	my %Small_cout=();
	my %Small_coutV2=();
	my %Small_RR_sum=();
	my %Small_D_sum=();



	$FileThis=$SplltPath[0];
	my $PopID=$SplltPath[1];
	push  @PopIDAryy , $PopID;

	if  ($FileThis =~s/\.gz$/\.gz/)
	{
		open BBC,"gzip -cd  $FileThis | "  || die "input file can't open $!" ;
	}
	else
	{
		open BBC,"$FileThis"  || die "input file can't open $!" ;
	}

	open OA,">$output.$PopID" || die "output file can't open $!" ;




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
			$hash_coutV2{$inf[0]}+=$inf[-1] if  ($inf[-2] ne "NA");
			$hash_D_sum{$inf[0]}+=$inf[-2] if  ($inf[-2] ne "NA");
			$hash_RR_sum{$inf[0]}+=$inf[-3];
		}
		else
		{
			$inf[0]=int($inf[0]/$Small_bin);
			$Small_cout{$inf[0]}+=$inf[-1] ;
			$Small_coutV2{$inf[0]}+=$inf[-1] if  ($inf[-2] ne "NA") ;
			$Small_D_sum{$inf[0]}+=$inf[-2] if  ($inf[-2] ne "NA") ;
			$Small_RR_sum{$inf[0]}+=$inf[-3];
		}
	}
	close BBC ;



	print OA "#Dist\tMean_r^2\tMean_D'\tSum_r^2\tSum_D'\tNumberPairs\n";


	foreach my $k (sort {$a<=>$b} keys %Small_cout)
	{
		my $mean_R=$Small_RR_sum{$k}/$Small_cout{$k};
		if  ($mean_R> $maxY_tmp) {	$maxY_tmp=$mean_R ;	}
		if (exists $Small_coutV2{$k})
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
		if  ($mean_R> $maxY_tmp) {	$maxY_tmp=$mean_R ;	}
		if  ( exists  $hash_coutV2{$k} )
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
}


close LIST ;



$maxX_tmp=int($maxX_tmp/1000);
$maxX||=$maxX_tmp;
if  ($maxY_tmp>0.96)
{
	$maxY_tmp=1;
}

my $R="/usr/bin/Rscript";
if  ( !(-e $R) )
{
	$R="/ifshk4/BC_PUB/biosoft/newblc/03.Soft_ALL/R-3.4.1/bin/Rscript";
}


if  ( !(-e $R) )
{
	$R=`which Rscript`;chomp $R;
}



my @ColArry ; 
$ColArry[0]="maroon";
$ColArry[1]="black";
$ColArry[2]="Darkblue";
$ColArry[3]="Purple";
$ColArry[4]="DarkGreen";
$ColArry[5]="DarkOrange3";
$ColArry[6]="DimGrey";
$ColArry[7]="Brown";
$ColArry[8]="Orange";
$ColArry[9]="Cyan";
$ColArry[10]="Grey";
$ColArry[11]="LightSkyBlue";
$ColArry[12]="Gold";
$ColArry[13]="IndianRed2";
$ColArry[14]="DeepSkyBlue2";
$ColArry[15]="Chartreuse2";
$ColArry[16]="Orchid";
$ColArry[17]="greenyellow";
$ColArry[18]="SlateGrey";
$ColArry[19]="LightSlateGray";
$ColArry[20]="Gold1";
$ColArry[21]="SaddleBrown";
$ColArry[22]="MidnightBlue";
$ColArry[23]="NavyBlue";
$ColArry[24]="YellowGreen";
$ColArry[25]="CornflowerBlue";
$ColArry[26]="MediumBlue";
$ColArry[27]="Blue";
$ColArry[28]="RoyalBlue";
$ColArry[29]="DeepPink";
$ColArry[30]="DeepSkyBlue1";
$ColArry[31]="MediumTurquoise";
$ColArry[32]="Turquoise";
$ColArry[33]="SpringGreen3";
$ColArry[34]="CadetBlue";
$ColArry[35]="DodgerBlue";
$ColArry[36]="MediumAquamarine";
$ColArry[37]="Aquamarine";
$ColArry[38]="Green";
$ColArry[39]="DarkOliveGreen";
$ColArry[40]="DarkSeaGreen";
$ColArry[41]="SeaGreen";
$ColArry[42]="MediumSeaGreen";
$ColArry[43]="LightSeaGreen";
$ColArry[44]="PaleGreen";
$ColArry[45]="SpringGreen";
$ColArry[46]="LawnGreen";
$ColArry[47]="Chartreuse";
$ColArry[48]="MedSpringGreen";
$ColArry[49]="GreenYellow";
$ColArry[50]="LimeGreen";
$ColArry[51]="OrangeRed2";
$ColArry[52]="DeepSkyBlue";
$ColArry[53]="Magenta3";
$ColArry[54]="SteelBlue";
$ColArry[55]="LightSteelBlue";
$ColArry[56]="LightBlue";
$ColArry[57]="PowderBlue";
$ColArry[58]="PaleTurquoise";
$ColArry[59]="DarkTurquoise";
$ColArry[60]="ForestGreen";
$ColArry[61]="OliveDrab";
$ColArry[62]="DarkKhaki";
$ColArry[63]="PaleGoldenrod";
$ColArry[64]="LtGoldenrodYello";
$ColArry[65]="Pink";
$ColArry[66]="LightYellow";
$ColArry[67]="LightGoldenrod";
$ColArry[68]="goldenrod";
$ColArry[69]="DarkGoldenrod";
$ColArry[70]="RosyBrown";
$ColArry[71]="IndianRed";
$ColArry[72]="Sienna";
$ColArry[73]="Peru";
$ColArry[74]="DarkSlateGray";
$ColArry[75]="Burlywood";
$ColArry[76]="SkyBlue";
$ColArry[77]="Beige";
$ColArry[78]="Wheat";
$ColArry[79]="SandyBrown";
$ColArry[80]="Tan";
$ColArry[81]="Chocolate";
$ColArry[82]="Firebrick";
$ColArry[83]="DarkSalmon";
$ColArry[84]="Salmon";
$ColArry[85]="LightSalmon";
$ColArry[86]="Coral";
$ColArry[87]="LightCoral";
$ColArry[88]="Tomato";
$ColArry[89]="OrangeRed";
$ColArry[90]="HotPink";
$ColArry[91]="LightPink";
$ColArry[92]="PaleVioletRed";
$ColArry[93]="Maroon";
$ColArry[94]="MediumVioletRed";
$ColArry[95]="VioletRed";
$ColArry[96]="Violet";
$ColArry[97]="Plum";
$ColArry[98]="DarkSlateBlue";
$ColArry[99]="SlateBlue";
$ColArry[100]="MediumSlateBlue";
$ColArry[101]="LightSlateBlue";
$ColArry[102]="MediumOrchid";
$ColArry[103]="DarkOrchid";
$ColArry[104]="DarkViolet";
$ColArry[105]="BlueViolet";
$ColArry[106]="MediumPurple";
$ColArry[107]="Thistle";
$ColArry[108]="Snow1";
$ColArry[109]="Snow2";
$ColArry[110]="Snow3";
$ColArry[111]="Snow4";
$ColArry[112]="Seashell1";
$ColArry[113]="Seashell2";
$ColArry[114]="Seashell3";
$ColArry[115]="Seashell4";
$ColArry[116]="AntiqueWhite1";
$ColArry[117]="AntiqueWhite2";
$ColArry[118]="AntiqueWhite3";
$ColArry[119]="AntiqueWhite4";
$ColArry[120]="Bisque1";





my $PopNumber=$#PopIDAryy ;


my $PopName=$PopIDAryy[0];
my $Plot=<<LOVE;
read.table("$output.$PopName")->$PopName;
plot($PopName\[,1\]/1000,$PopName\[,2\],type="l",col="$ColArry[0]",main="LD decay",xlab="Distance(Kb)",xlim=c(0,$maxX),ylim=c(0,$maxY_tmp),ylab=expression(r^{2}),bty="n")
LOVE

my $legendCol="\"$ColArry[0]\"";
my $legendName="\"$PopName\"";
my $legendlty=1;

for (my $IDE=1; $IDE<= $PopNumber; $IDE++)
{

	$PopName=$PopIDAryy[$IDE];
	$Plot.=<<LOVE;
read.table("$output.$PopName")->$PopName;
lines($PopName\[,1\]/1000,$PopName\[,2\],col="$ColArry[$IDE]")
LOVE

	$legendCol.=",\"$ColArry[$IDE]\"";
	$legendName.=",\"$PopName\"";
	$legendlty.=",1";
}


my $Rshell=<<HEWM;
pdf("$output.pdf")
$Plot
legend("topright",c($legendName),col=c($legendCol),cex=1,lty=c($legendlty),bty="n");
dev.off()
png("$output.png")
$Plot
legend("topright",c($legendName),col=c($legendCol),cex=1,lty=c($legendlty),bty="n");
dev.off()

HEWM

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



