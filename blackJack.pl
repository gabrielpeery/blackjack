#!/bin/perl
#############################################################
#						Black Jack 1.0						#
# Author:		Gabriel Peery								#	
# Version:		1.0											#
# Description:  This is a basic appliction that will		#
#				run through a basic Game of blackJack.		#
#				As the applicatoin runs you will be			#
#				provided instructions.						#
# Bug Fixes:	If you see any bugs, or issues you would	#
#				like to report, please feel free to email	#
#				me@gabrielpeery.com.						#
#############################################################

# Module dependancy declerations #
use strict;
#use warnings;
use List::Util 'max';
use Scalar::Util qw(looks_like_number);
use DBI;
use DBD::mysql;


# variable initialization #
my $playerID;
my $host = "localhost";
my $DBusername = "gpeerybl_21";
my $database = "gpeerybl_21";
my $password = "O\$gGH3c)c?%N";
my $total;
my $money; 
my $playerMoney;
my $isPlayer;
my $hitStay;
my @usedCards;
my $playerBet;
my $updateCashQ;
my $updateCashHandle;
my @dealersHand;
my $dealerTotal = 0;
my $firstCardPlayer;
my $secondCardPlayer;
my $dealerCard;
my $dealerCardValue;
my $thirdCardPlayer;
my @playersHand;
my $dbh = DBI->connect('dbi:mysql:gpeerybl_21:localhost',$DBusername,$password) or die "connection error: $DBI::errstr\n";



# This is where I verify if the user has a user ID. 
# I use this to track the users money and winnings in
# the db. 
# 
# I intend on making this more elegant, but the moment
# it functions.

print "please provide a username\n";
my $username = <>;
chomp($username);

my $isPlayerQ = "SELECT username FROM money WHERE username='$username';";
my $isPlayeryHandle = $dbh->prepare($isPlayerQ);
$isPlayeryHandle->execute();
$isPlayeryHandle->bind_columns(undef,\$isPlayer);

while($isPlayeryHandle->fetch()){
    $isPlayer = $isPlayer;
}

# In this section I determine whether the user ID provided exists.
# If it does it passes to next section, otherwise, it offers the
# creation of a new user.

if (!defined($isPlayer)) {
	print "the player ID: $username does not exist.\n Would you like to createa a player?\nyes (1) no (2)\n";
	my $newPlayer = <>;
	chomp($newPlayer);
	if ($newPlayer == 1){
        my $newPlayerQ = "INSERT INTO  money (money,username) VALUES (500,'$username');";
        my $newPlayerHandle = $dbh->prepare($newPlayerQ);
        $newPlayerHandle->execute();
		print "New player has been created. Good luck and don't go broke!";
	}else{
		print "I am sorry to hear that, Maybe later than.\n\nGoodbye";exit;
	}
}

# After a player has been identified/created I use another mysql query
# to get the amount of money they have.

my $getCashTotalQ = "SELECT money FROM money WHERE username='$username';";
my $getCashHandle = $dbh->prepare($getCashTotalQ);
$getCashHandle->execute();
$getCashHandle->bind_columns(undef,\$money);

while($getCashHandle->fetch()){
	$playerMoney = $money;
}

# check to see if the user is too far in debt (-500) If they are
# They are no longer allowed to play the game.

if ($playerMoney <= -500) {
	print "\nYou have run out of money, in fact, you owe me money...\nPlease leave my table!\n";
	exit;
}

# This next section is used to take the player/users bet.

print "\n You currently have: $playerMoney\n\n How much would you like to bet? \n\n";
$playerBet = <>;
chomp($playerBet);

# here we check to make sure that the user has input a valid value.
# It disallows them to use anything other than positive numbers.
# also, this section insults you for trying silly things.

while(!looks_like_number($playerBet) || $playerBet < 0) {
	if (!looks_like_number($playerBet)){
	print "\nPlease select a number, You can't bet letters dumby!\n";
	$playerBet = <>;
	chomp($playerBet);
	}
	if($playerBet < 0){
		print "please select a value greater than 0, you're trying to make money right?\n";
		$playerBet = <>;
		chomp($playerBet);
	}
}

# here we check to make sure that you aren't betting 
# more than you actually have. The application will
# allow you to borrow up to 500. I also update the 
# current ammount of money on hand at this point.

while($playerBet > $playerMoney + 500){
	print "You only have $playerMoney, and you tried to bet $playerBet..\nNow I like you, so I will allow you to borrow up to \$500 from me.\nLets try again, what's your bet?\n";
	$playerBet = <>;
	chomp($playerBet);
}

# update the users total money less the bet made.

$playerMoney -= $playerBet;

# the next sub routine is intended to determin the 
# outcome of the users hand (score) and the dealers.
# the sub routine take one arguemnt: outcome. This is 
# given in the form of 1 or 0 (not one). If 1 is provided
# your outcome was winning and it will take the bet
# the user placed, double it, and at it the the money
# on hand (that is the money you started with less the
# bet) and updates the data for your user in the database

sub updateCashSR {
	my $subOutcome = $_[0];
	if ($subOutcome == 1) {
		$playerMoney += $playerBet + $playerBet;
		$updateCashQ = "UPDATE money SET money='$playerMoney' WHERE username='$username';";
		$updateCashHandle = $dbh->prepare($updateCashQ);
		$updateCashHandle->execute();
	}else{
		$updateCashQ = "UPDATE money SET money='$playerMoney' WHERE username='$username';";
		$updateCashHandle = $dbh->prepare($updateCashQ);
		$updateCashHandle->execute();
	}
}

# this next sub routine is used to print information
# to the user to keep them up to date on the game.
# it shows them their total money (less the bet) the
# amount they bet, and the current score ($total) of
# their hand.

sub moneyPrint {
	printf("%-10s %-10s %-10s", "Cash: $playerMoney","Bet: $playerBet","Current Score: $total\n");
}

# Here I populate my deck array. this is for user 
# readability while the application is running. 
# I default the first value to 0 for readability
# as well.

sub printHands {

	printf ("%-20s %20s","Players Hand:$total", "Dealers Hand:$dealerTotal\n");

	for (0 .. max($#dealersHand,$#playersHand)) {
	    if(defined($playersHand[$_])){printf ("%-20s", "$playersHand[$_]");
	    }else{printf("%-20s");};
	    if(defined($dealersHand[$_])){printf ("%20s","$dealersHand[$_]\n");
		}else{printf("%20s\n");};
	};

}

# This sub routine checks your score when 
# your total changes if you have 21 or 
# higher than 21 and ends the game accordingly

sub winBust {
	if ($total == 21){
        updateCashSR(1);
		moneyPrint();
		print "You scored 21!, this means you win and the dealer pays!\n";
		exit;
	}elsif($total > 21){
        updateCashSR(0);
        moneyPrint();
        print "your score exceeded 21 with a score of $total\nThis means you lose and the dealer wins.\n";
		exit;
	}
}

# Here the deck Array is built

my @deck = (
		"ace of spades",#0
		"2 of spades",
		"3 of spades",
		"4 of spades",
		"5 of spades",
		"6 of spades",
		"7 of spades",
		"8 of spades",
		"9 of spades",
		"10 of spades",
		"jack of spades",
		"queen of spades",
		"king of spades",#12
		"ace of diamonds",#13
		"2 of diamonds",
		"3 of diamonds",
		"4 of diamonds",
		"5 of diamonds",
		"6 of diamonds",
		"7 of diamonds",
		"8 of diamonds",
		"9 of diamonds",
		"10 of diamonds",
		"jack of diamonds",
		"queen of diamonds",
		"king of diamonds",#25
		"ace of hearts",#26
		"2 of hearts",
		"3 of hearts",
		"4 of hearts",
		"5 of hearts",
		"6 of hearts",
		"7 of hearts",
		"8 of hearts",
		"9 of hearts",
		"10 of hearts",
		"jack of hearts",
		"queen of hearts",
		"king of hearts",#38
		"ace of clubs",#39
		"2 of clubs",
		"3 of clubs",
		"4 of clubs",
		"5 of clubs",
		"6 of clubs",
		"7 of clubs",
		"8 of clubs",
		"9 of clubs",
		"10 of clubs",
		"jack of clubs",
		"queen of clubs",
		"king of clubs",#51
);	

# This next sub routine is used to place 
# values on cards. I take which card from 
# the deck, reduces it down to a value of 
# 0 - 12 (13 cards per suite) and returns
# that value. If the card is returned 0
# or an ace, I use the ace sub routine
# to give you the option to choose a 
# 1 or an 11.

sub cardValue{
	if ($_[0] >= 0 && $_[0] <= 12) {
		$_[0] + 1;		
	}elsif ($_[0] >= 13 && $_[0] <= 25) {
		$_[0] - 12
	}elsif ($_[0] >= 26 && $_[0] <= 38) {
		$_[0] - 25;		
	}elsif ($_[0] >= 39 && $_[0] <= 51) {
		$_[0] - 38;		
	};
};


# give the first two cards for the user

$firstCardPlayer = int(rand($#deck));
$secondCardPlayer = int(rand($#deck));

# here I check to make sure that the second
# card delt to the player is not the same as
# the first. If it is, I remove 'reroll' a 
# new card.

while($secondCardPlayer == $firstCardPlayer) {
	$secondCardPlayer = int(rand($#deck));
}

# Givers a score value to the first two cards provided.

my $firstCardValue = cardValue($firstCardPlayer);
my $secondCardValue = cardValue($secondCardPlayer);

# here is the is where the application takes face
# cards and provides them with a value of 10. 

if ($firstCardValue >= 11){$firstCardValue = 10};
if ($secondCardValue >= 11){$secondCardValue = 10};

# Here we use the push function to add the 
# cards that are being used to an array 
# that is later called to display the users
# hand.

push(@usedCards, $firstCardPlayer);
push(@usedCards, $secondCardPlayer);

# this is where we begin to give output to the user
# You will be shown your first card and second card.
# this also provides a value to the $total. Which is 
# the users score.

print "\nyour first card was $deck[$firstCardPlayer] :		 $firstCardValue\n";
print "\nyour second card was card was $deck[$secondCardPlayer] :	 $secondCardValue\n";
$total = $firstCardValue + $secondCardValue;

# the next sub routine is used to give the user 
# the option to choose a score when if ace is
# drawn.

sub ace {
if ($_[0] == 1){ 
		moneyPrint();
		print "\nThis card was an ace, would you like it to have a value of 1 or 11?\n";
		$_[0] = <>;
		chomp($_[0]);
		while ($_[0] != 1 && $_[0] != 11) {
			moneyPrint();
			print "\nyou need to select a value of 11 or 1\n";
			$_[0] = <>;
			chomp($_[0]);
		};
		$_[0];
	};
};



# checking if the first or second card are aces

ace($firstCardValue);
ace($secondCardValue);

$total = $firstCardValue + $secondCardValue;
winBust();

# in this next section the application controls
# the hit or stay mechanic in a game of blackjack.
# First it shows you the current score and askes if
# you would like to hit or stay.

moneyPrint();
print "would you like to hit (1) or stay (2)?";
$hitStay = <>;
chomp($hitStay);

# checks to make sure you chose a 1 or a 2 in your answer.

if ($hitStay != 1 && $hitStay != 2) {
	print "you much select 1 or 2\n";
	$hitStay = <>;
	moneyPrint();
}

# this while look will keep you hitting until
# you choose to stay, this chaning the variable 
# for $hitStay to 2, closing the loop
# While you are still hitting, the look will 
# give you a new card, at the value of the card 
# to your total, and add the face of the card
# to your hand. All the while checking to make
# sure that your still not busting, or hitting
# 21 with the winBust(); sub routine 

while ($hitStay == 1) {
	if ($hitStay == 1){
		$thirdCardPlayer = int(rand($#deck));

		if ($thirdCardPlayer == $firstCardPlayer || $thirdCardPlayer == $secondCardPlayer){
			$thirdCardPlayer = int(rand($#deck));
		};
	}
	push(@usedCards, $thirdCardPlayer);
	my $thirdCardValue = cardValue($thirdCardPlayer);
	ace($thirdCardValue);
	if ($thirdCardValue >= 11){$thirdCardValue = 10};
	print "your third card was $deck[$thirdCardPlayer] : $thirdCardValue \n\n";
	
	$total = $total + $thirdCardValue;
	winBust();
	moneyPrint();
	print "would you like to hit (1) or stay (2)?\n";
	$hitStay = <>;
	chomp($hitStay);
	if ($hitStay != 1 && $hitStay != 2) {
		print "you much select 1 or 2";
		$hitStay = <>;
		chomp($hitStay);
	}
}


# This creates another array for the hand you were delt. 

foreach (@usedCards) {
	push(@playersHand, $deck[$_]);
}

winBust();

# This is where the application deals with the
# dealers. this portion is a lot smaller due to 
# it being simple logic and little control by the
# player. Rules state that a dealer has to hit until 
# at least 17, logically, a dealer will hit until 
# are either winning the player (with a score higher
# than 17), hit 21 or bust. 

while ($dealerTotal <= 17 || $dealerTotal < $total) {

# Give the dealer a card, and give that card a value

	$dealerCard = int(rand($#deck));
	$dealerCardValue = cardValue($dealerCard);
	
# this handles the face cards for the dealer, also
# catches if you get an ace, and allows it to be a 
# score of 11

	if ($dealerCardValue >= 11 && $dealerCard != 0){$dealerCardValue = 10};
	
# enter ace logic. As it's the only real choice 
# the dealer has there is a simple rule. choose 11
# unless you will bust. 

	if ($dealerCardValue == 0){
		if ($dealerTotal > 12) {
			$dealerCardValue = 1;	
		}else{
			$dealerCardValue = 11;
		}
	}

# check if the card was previously used by user

	foreach (@usedCards){
		if ($dealerCard == $_){
			$dealerCard = int(rand($#deck));
		} 
	};

# pushes dealers hand into an array for display

	push(@dealersHand, $deck[$dealerCard]);
	$dealerTotal = $dealerTotal + $dealerCardValue;
	
# checks if dealer has busted or not	

	if( $dealerTotal > 21) {
		printHands();
		updateCashSR(1);
		print "\nThe Dealer Busted with a score of $dealerTotal, you won with a score of $total\n";
		exit;
	};
};

# checks totals against each other and declares a winner.

if ($dealerTotal > $total) {
	printHands();
	updateCashSR(0);	
	print "\nYou lost: $total. Dealer Wins: $dealerTotal\n";
}elsif( $dealerTotal < $total) {
	printHands();
	updateCashSR(1);	
	print "\nYou win: $total. Dealer Loses: $dealerTotal\n";	
}else{
	printHands();
	print "Looks like you tied, house rule, no one wins no one loses\n";
};

