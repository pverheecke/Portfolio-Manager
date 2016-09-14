#!/usr/bin/perl -w

use Time::ParseDate;

my $debug = 0;
my @sqlinput = ();
my @sqloutput = ();

use strict;

use CGI qw(:standard);

use DBI;

use Time::ParseDate;

my $dbuser = "pdv454";
my $dbpasswd = "zmHlvVl66";

my $cookiename = "PSession";
my $debugcookiename = "PDebug";

my $inputcookiecontent = cookie($cookiename);
my $inputdebugcookiecontent = cookie($debugcookiename);

my $outputcookiecontent = undef;
my $outputdebugcookiecontent = undef;
my $deletecookie = 0;
my $user = undef;
my $password = undef;
my $logincomplain = 0;

my $action;
my $run;

if (defined(param("act"))) {
	$action = param("act");
	if (defined(param("run"))) {
		$run = param("run") == 1;
	} else {
		$run = 0;
	}
} else {
	$action = "base";
	$run = 1;
}

my $dstr;

if (defined(param("debug"))) {
	if (param("debug") == 0) {
		$debug = 0;
	} else {
		$debug = 1;
	}
} else {
	if (defined($inputdebugcookiecontent)) {
		$debug = $inputdebugcookiecontent;
	} else {
		
	}
}

$outputdebugcookiecontent = $debug;



if (defined($inputcookiecontent)) {
	($user,$password) = split(/\//,$inputcookiecontent);
	$outputcookiecontent = $inputcookiecontent;
} else {
	($user,$password) = ("anon","anonanon");
}


if ($action eq "login") {
	if ($run) {
		($user,$password) = (param("user"),param("password"));
		if (ValidUser($user,$password)) {
			$outputcookiecontent = join("/",$user,$password);
			$action = "base";
			$run = 1;
		} else {
			$logincomplain = 1;
			$action = "login";
			$run = 0;
		}
	} else {
		undef $inputcookiecontent;
		($user,$password) = ("anon","anonanon");
	}
}


if ($action eq "logout") {
	$deletecookie = 1;
	$action = "base";
	$user = "anon";
	$password = "anonanon";
	$run = 1;
}


my @outputcookies;

if (defined($outputcookiecontent)) {
	my $cookie=cookie(-name=>$cookiename,
			  -value=>$outputcookiecontent,
			  -expires=>($deletecookie ? '-1h' : '+1h'));
	push @outputcookies, $cookie;
}


if (defined($outputdebugcookiecontent)) {
	my $cookie=cookie(-name=>$debugcookiename,
			  -value=>$outputdebugcookiecontent);
	push @outputcookies, $cookie;
}


print header(-expires=>'now',
	     -cookie=>\@outputcookies);


#
# BEGIN HTML
#
#

print "<html style=\"height: 100\%\">";
print "<head>";
print "<title>Portfolio Manager</title>";
print "</head>";

print "<body style=\"height:100\%;margin:0\">";
print "<style type=\"text/css\">\n\@import \"portfolio.css\";\n</style>\n";

print "<center>" if !$debug;
print "<script type=\"text/javascript\" src=\"portfolio.js\"> </script>";
print h1("Portfolio Manager");



#
# LOGIN
#
#

if ($action eq "login") {
	if ($logincomplain) {
		print "Login failed.  Try again.<p>";
	}
	if ($logincomplain or !$run) {
		print start_form(-name=>'Login'),
			h2('Login'),
			"Name: ",textfield(-name=>'user'), p,
			"Password: ",textfield(-name=>'password'), p,
			hidden(-name=>'act', default=>['login']),
			hidden(-name=>'run', default=>['1']),
			submit,
			end_form;				
		print "<p>Don't have an account yet? <a href=\"portfolio.pl?act=register\">Register here</a></p>";
	}
}

#
# REGISTER
#
#

if ($action eq "register") {
	if (!$run) {
		print start_form(-name=>'Register'),
			h2('Register'),
			"Username: ",textfield(-name=>'regu'), p,
			"Password: ",textfield(-name=>'regp'), p,
			hidden(-name=>'act', -default=>['register'], -override=>1),
			hidden(-name=>'run', -default=>['1'], -override=>1),
			submit,
			end_form;
	} else {
		my $regu = param("regu");
		my $regp = param("regp");
		my $error;
		$error = Register($regu,$regp);
		if ($error) {
			print "Unable to register because $error";
			print "<p><a href=\"portfolio.pl?act=register\">Try again</a></p>";
			print "<p><a href=\"portfolio.pl?act=base\">Return home</a></p>";
		} else {
			print h2("Welcome to the Portfolio Manager, $regu!");
			print h2("<a href=\"portfolio.pl?act=login&run=1&user=$regu&password=$regp\">Click here to login</a>");
		}
	}
}


#
# BASE
#
#

if ($action eq "base") {
	print h2("Welcome, $user!");
	
	if ($debug) {
		print "<div id=\"data\" style=\"width:100\%; height:10\%\"></div>";
	} else {
		print "<div id=\"data\" style=\"display: none;\"></div>";
	}

	if ($user eq "anon") {
		print "<p>You are anonymous, please <a href=\"portfolio.pl?act=login\">login</a> to view your portfolios</p>";
		print "<p>Don't have an account yet? <a href=\"portfolio.pl?act=register\">Register here</a></p>";
	} else {
		print "<div id=\"portfoliolist\" style=\"width:100\%; height:40\%\">";
		print h3('You currently own the following portfolios:');
		my (@portfolio_list, $error) = GetPortfolios($user);
		if (!$error) {
			foreach (@portfolio_list) {
				if ($_ >= 0) {
					my ($portfolio_name, $error) = GetPortfolioName($_);
					if (!$error) {
						print "<p><a href=\"portfolio.pl?act=overview&id=$_\">$portfolio_name</a></p>";
					}
				}
			}
		}
		print "</div>";
		print "<p><a href=\"portfolio.pl?act=addportfolio\">Add new portfolio</a></p>";
		print "<p><a href=\"portfolio.pl?act=logout&run=1\">Logout</a></p>";
	}
}


if ($action eq "addportfolio") {
	if (!$run) {
		print h2("Add New Portfolio");
		my ($id,$error) = GetNewID();
		print start_form(-name=>'Add'),
			"Enter a name for your portfolio: ", textfield(-name=>'pname'),p,
			hidden(-name=>'act', -value=>'addportfolio', -override=>1),
			hidden(-name=>'run',-value=>'1', -override=>1),
			hidden(-name=>'id', -value=>$id, -override=>1),
			submit,
			end_form;
	} else {
		my $pname = param("pname");
		my $id = param("id");
		my $error = AddNewPortfolio($user,$id,$pname);
		if ($error) {
			print "Could not add portfolio because $error";
		} else {
			print h2("$pname added successfully!");
		}
	}
	print "<p><a href=\"portfolio.pl?act=base\">Return home</a></p>";
}

if ($action eq "overview") {
	my $id = param("id");
	my ($portfolio_name, $err1) = GetPortfolioName($id);
	my ($portfolio_cash, $err2) = GetPortfolioCash($id);
	my (@portfolio_stocks, $err3) = GetStocks($id);
	my $total;
	if (!$err1 && !$err2 && !$err3) {
		print h2("Portfolio Overview: $portfolio_name");
		print "<p>Cash Account: \$$portfolio_cash<br>";
		$total = $total + $portfolio_cash;
		print "<a href=\"portfolio.pl?act=deposit&id=$id\">Deposit</a>";
		print "  |  <a href=\"portfolio.pl?act=withdraw&id=$id\">Withdraw</a></p>";
		print h4("Stocks - <a href=\"portfolio.pl?act=buysell&id=$id\">Edit</a>");
		my @stock_list;
		foreach (@portfolio_stocks) {
			if ($_) {
				my $symbol = $_->[0];
				push(@stock_list,$symbol);
				my $shares = $_->[1];
				my ($close,$err4) = GetRecentClose($symbol);
				my $value = $shares*$close;
				print "<p>$symbol - $shares shares";
				print "<br>Present Market Value: \$$value";
				print "<br><a href=\"portfolio.pl?act=details&symbol=$symbol&id=$id&cash=$portfolio_cash\">View more details</a>";
				$total = $total + $value;
				print "</p>";
			}
		}
		print start_form(-name=>'Matrix'),
			h4("Covariance/Correlation Matrices"),p,
			"Start Date: ",textfield(-name=>'start'),p,
			"End Date: ",textfield(-name=>'end'),p,
			hidden(-name=>'act', -value=>'matrix', -override=>1),
			hidden(-name=>'symbols', -value=>\@stock_list),
			hidden(-name=>'id', -value=>$id, -override=>1),
			submit(-value=>'Calculate'),
			end_form;
		print h3("Total Present Market Value: \$$total");

	}
	print "<a href=\"portfolio.pl?act=base\">Return home</a>";
}

if ($action eq "matrix") {
	my @symbols = param("symbols");
	my $start = parsedate(param("start"));
	my $end = parsedate(param("end"));
	my $id = param("id");
	CreateMatrix($start,$end,@symbols);
	print "<p><a href=\"portfolio.pl?act=overview&id=$id\">Back</a></p>";
	print "<p><a href=\"portfolio.pl?act=base\">Return home</a></p>";
}


if ($action eq "quote") {
	my $id = param("id");
	my $symbol = param("symbol");
	my $cash = param("cash");
	print h2("$symbol -- Add New Information");
	if (!$run) {
		print start_form(-name=>'Quote'),
			"Open Price: ",textfield(-name=>'open'),p,
			"Close Price: ",textfield(-name=>'close'),p,
			"Low Price: ",textfield(-name=>'low'),p,
			"High Price: ",textfield(-name=>'high'),p,
			"Volume: ",textfield(-name=>'volume'),p,
			"Date: (e.g. 01/01/2011) ",textfield(-name=>'date'),p,
			hidden(-name=>'act', -value=>'quote', -override=>1),
			hidden(-name=>'run', -value=>'1', -override=>1),
			hidden(-name=>'symbol', -value=>$symbol, -override=>1),
			submit,
			end_form;
	} else {
		my $open = param("open");
		my $close = param("close");
		my $low = param("low");
		my $high = param("high");
		my $volume = param("volume");
		my $date = parsedate(param("date"));
		my $error = AddInformation($symbol,$open,$close,$low,$high,$volume,$date);
		if ($error) {
			print "Unable to add stock information because $error";
		} else {
			print h3("Your information has been successfully processed.");
		}
	}
	print "<p><a href=\"portfolio.pl?act=details&symbol=$symbol&id=$id&cash=$cash\">Back</a></p>";
	print "<p><a href=\"portfolio.pl?act=base\">Return home</a></p>";
}



if ($action eq "details") {
	my $symbol = param("symbol");
	my $id = param("id");
	my $cash = param("cash");
	my $cov;
	my $beta;
	my $from;
	my $to;
	my $error;
	my $err;
	if ($run) {
		$from = parsedate(param("start"));
		$to = parsedate(param("end"));
		($cov, $error) = GetCOV($symbol,$from,$to);
		$beta = GetBeta($symbol,$from,$to);
	}
	print h2("$symbol -- More Details");
	print "<p><a href=\"portfolio.pl?act=quote&symbol=$symbol&id=$id&cash=$cash\">Add new daily information</a></p>";
	print "<p><a href=\"portfolio.pl?act=graph&symbol=$symbol&id=$id&cash=$cash\">View historical graph</a></p>";
	print "<p><a href=\"portfolio.pl?act=predict&symbol=$symbol&id=$id&cash=$cash\">View prediction graph</a></p>";
	print "<p><a href=\"portfolio.pl?act=strategy&symbol=$symbol&id=$id&cash=$cash\">View automated trading strategy</a></p>";
	print h3("Coefficient of Variance (COV): ");
	if ($run) { print "$cov"; }
	print h3("Beta: ");
	if ($run) { print "$beta<br>"; }
	print start_form(-name=>'COV'),
		"Enter start date (e.g. 01/01/1991): ",textfield(-name=>'start'),p,
		"Enter end date (e.g. 12/01/1991): ",textfield(-name=>'end'),p,
		hidden(-name=>'act', -value=>'details', -override=>1),
		hidden(-name=>'run', -value=>'1', -override=>1),
		hidden(-name=>'id', -value=>$id, -override=>1),
		hidden(-name=>'symbol', -value=>$symbol, -override=>1),
		submit(-value=>'Calculate'),
		end_form;
	print "<p><a href=\"portfolio.pl?act=overview&id=$id\">Back</a></p>";
	print "<p><a href=\"portfolio.pl?act=base\">Return home</a></p>";
}


if ($action eq "graph") {
	my $symbol = param("symbol");
	my $id = param("id");
	my $cash = param("cash");
	print h2("Historical Graph: $symbol");
	if (!$run) {
		print start_form(-name=>'graph'),
			"Enter start date (e.g. 01/01/1991): ",textfield(-name=>'start'),p,
			"Enter end date (e.g. 01/01/1991): ",textfield(-name=>'end'),p,
			hidden(-name=>'act', -value=>'graph', -override=>1),
			hidden(-name=>'run', -value=>'1', -override=>1),
			hidden(-name=>'id', -value=>$id, -override=>1),
			hidden(-name=>'symbol', -value=>$symbol, -override=>1),
			submit,
			end_form;
	} else {
		my $start_str = param("start");
		my $end_str = param("end");
		print h3("Start: $start_str");
		print h3("End: $end_str");
		my $start = parsedate($start_str);
		my $end = parsedate($end_str);
		my $err = PlotHistory($symbol,$start,$end);
		if ($err) { print "No graph available."; } else {
			print "<p><img src=\"$symbol\_$start\_$end.png\" /></p>";
		}
	}
	print "<p><a href=\"portfolio.pl?act=details&symbol=$symbol&id=$id&cash=$cash\">Back</a></p>";
	print "<p><a href=\"portfolio.pl?act=base\">Return home</a></p>";
}

if ($action eq "predict") {
	my $symbol = param("symbol");
	my $id = param("id");
	my $cash = param("cash");
	print h2("Predictive Graph: $symbol");
	if (!$run) {
		print start_form(-name=>'predict'),
			"Enter start date (e.g. 01/01/2016): ",textfield(-name=>'start'),p,
			"Enter end date (e.g. 01/01/2017): ",textfield(-name=>'end'),p,
			hidden(-name=>'act', -value=>'predict', -override=>1),
			hidden(-name=>'run', -value=>'1', -override=>1),
			hidden(-name=>'id', -value=>$id, -override=>1),
			hidden(-name=>'symbol', -value=>$symbol, -override=>1),
			submit,
			end_form;

	} else {
		my $start_str = param("start");
		my $end_str = param("end");
		print h3("Start: $start_str");
		print h3("End: $end_str");
		my $start = parsedate($start_str);
		my $end = parsedate($end_str);
		my $err = 1;
		#$err = PlotPredict($symbol,$start,$end);
		if ($err) {
			print "Unable to generate graph";
		} else {
			print "<p><img src=\"$symbol\_$start\_$end.png\" /></p>";
		}
	}
	print "<p><a href=\"portfolio.pl?act=details&symbol=$symbol&id=$id&cash=$cash\">Back</a></p>";
	print "<p><a href=\"portfolio.pl?act=base\">Return home</a></p>";
	
}

if ($action eq "strategy") {
	my $symbol = param("symbol");
	my $id = param("id");
	my $cash = param("cash");
	print h2("Automated Trading Strategy for $symbol: Shannon Ratchet");
	if (!$run) {
		print start_form(-name=>'strategy'),
			"Enter start date (e.g. 01/01/2001): ",textfield(-name=>'start'),p,
			"Enter end date (e.g. 02/01/2001): ",textfield(-name=>'end'),p,
			"Enter trading cost: ",textfield(-name=>'cost'),p,
			hidden(-name=>'act', -value=>'strategy', -override=>1),
			hidden(-name=>'run', -value=>'1', -override=>1),
			hidden(-name=>'cash', -value=>$cash, -override=>1),
			hidden(-name=>'id', -value=>$id, -override=>1),
			hidden(-name=>'symbol', -value=>$symbol, -override=>1),
			submit,
			end_form;		 	
	} else {
		my $cost = param("cost");
		my $start = param("start");
		my $end = param("end");
		my $result = `./shannon_ratchet.pl $symbol $cash $cost $start $end`;
		print h3("Start: $start");
		print h3("End: $end");
		print "<pre>$result</pre>";
	}
	print "<p><a href=\"portfolio.pl?act=details&symbol=$symbol&id=$id&cash=$cash\">Back</a></p>";
	print "<p><a href=\"portfolio.pl?act=base\">Return home</a></p>";

}


if ($action eq "deposit") {
	my $id = param("id");
	my ($portfolio_name, $err1) = GetPortfolioName($id);
	if (!$run) {
		my ($portfolio_cash, $err2) = GetPortfolioCash($id);
		if (!$err1 && !$err2) {
			print h2("Deposit Cash: $portfolio_name");
			print "<p>Current Balance: \$$portfolio_cash</p>";
			print start_form(-name=>'Deposit'),
				"Cash to deposit: ",textfield(-name=>'amnt'),p,
				hidden(-name=>'act', -value=>'deposit', -override=>1),
				hidden(-name=>'run', -value=>'1', -override=>1),
				hidden(-name=>'id', -value=>$id, -override=>1),
				submit,
				end_form;
		
		}
	} else {
		my $amnt = param("amnt");
		my $error = DepositCash($id, $amnt);
		if (!$error) {
			my ($portfolio_cash, $err) = GetPortfolioCash($id);
			print h2("Deposit Cash: $portfolio_name");
			print h2("Your deposit was successful!");
			print "<p>Current Balance: $portfolio_cash</p>";
		} else {
			print "Could not deposit cash because $error";
		}
	}
	print "<p><a href=\"portfolio.pl?act=overview&id=$id\">Back to Overview</a></p>";
	print "<p><a href=\"portfolio.pl?act=base\">Return home</a></p>";
}

if ($action eq "withdraw") {
	my $id = param("id");
	my ($portfolio_name, $err1) = GetPortfolioName($id);
	if (!$run) {
		my ($portfolio_cash, $err2) = GetPortfolioCash($id);
		if (!$err1 && !$err2) {
			print h2("Withdraw Cash: $portfolio_name");
			print "<p>Current Balance: \$$portfolio_cash</p>";
			print start_form(-name=>'Withdraw'),
				"Cash to withdraw: ",textfield(-name=>'amnt'),p,
				hidden(-name=>'act', -value=>'withdraw', -override=>1),
				hidden(-name=>'run', -value=>'1', -override=>1),
				hidden(-name=>'id', -value=>$id, -override=>1),
				submit,
				end_form;
		}
	} else {
		my $amnt = param("amnt");
		my $error = WithdrawCash($id, $amnt);
		if (!$error) {
			my ($portfolio_cash, $err) = GetPortfolioCash($id);
			print h2("Withdraw Cash: $portfolio_name");
			print h2("Your withdrawal was successful!");
			print "<p>Current Balance: $portfolio_cash</p>";
		} else {
			print "Could not withdraw cash because $error";
		}
	}
	print "<p><a href=\"portfolio.pl?act=overview&id=$id\">Back to Overview</a></p>";
	print "<p><a href=\"portfolio.pl?act=base\">Return home</a></p>";
	
}

if ($action eq "buysell") {
	my $id = param("id");
	my ($portfolio_name, $err1) = GetPortfolioName($id);
	if (!$run) {
		print h2("Update Stock Transactions: $portfolio_name");
		print start_form(-name=>'Buysell'),
			radio_group(-name=>'type',
				    -values=>['Buy','Sell'],
				    -default=>'Buy'),p,
			"Stock Symbol (e.g. AAPL): ", textfield(-name=>'symbol'),p,
			"Number of shares: ", textfield(-name=>'shares'),p,
			"Strike Price: ", textfield(-name=>'price'),p,
			hidden(-name=>'act', -value=>'buysell', -override=>1),
			hidden(-name=>'run', -value=>'1', -override=>1),
			hidden(-name=>'id', -value=>$id, -override=>1),
			submit,
			end_form;
	} else {
		my $type = param("type");
		my $symbol = param("symbol");
		my $shares = param("shares");
		my $price = param("price");
		my $error;
		if ($type eq "Buy") {
			$error = BuyShares($id,$symbol,$shares, $price);
		} else {
			$error = SellShares($id,$symbol,$shares, $price);
		}
		if (!$error) {
			print h2("Thank you for updating your portfolio!");
		} else {
			print "Could not update transaction because $error";
		}
	}
	print "<p><a href=\"portfolio.pl?act=overview&id=$id\">Back to Overview</a></p>";
	print "<p><a href=\"portfolio.pl?act=base\">Return home</a></p>";

}


print "</center>" if !$debug;

if ($debug) {
  print hr, p, hr,p, h2('Debugging Output');
  print h3('Parameters');
  print "<menu>";
  print map { "<li>$_ => ".escapeHTML(param($_)) } param();
  print "</menu>";
  print h3('Cookies');
  print "<menu>";
  print map { "<li>$_ => ".escapeHTML(cookie($_))} cookie();
  print "</menu>";
  my $max= $#sqlinput>$#sqloutput ? $#sqlinput : $#sqloutput;
  print h3('SQL');
  print "<menu>";
  for (my $i=0;$i<=$max;$i++) { 
    print "<li><b>Input:</b> ".escapeHTML($sqlinput[$i]);
    print "<li><b>Output:</b> $sqloutput[$i]";
  }
  print "</menu>";
}

print end_html;


sub GetNewID {
	my @largest;
	my $value;
	eval { @largest=ExecSQL($dbuser,$dbpasswd, "select max(id) from pm_portfolios","COL"); };
	if ($@) {
		return (undef,$@);
	} else {
		$value = $largest[0] + 1;
		return ($value,$@);
	}
}

sub AddNewPortfolio {
	my ($username,$id,$name) = @_;
	eval { ExecSQL($dbuser,$dbpasswd, "insert into pm_portfolios (username,id,name,cash) values(?,?,?,0)",undef,$username,$id,$name); };
	if ($@) {
		return $@;
	} else {
		return undef;
	}
}

sub GetPortfolioCash {
	my ($portfolio) = @_;
	my @cash;
	eval { @cash=ExecSQL($dbuser,$dbpasswd, "select cash from pm_portfolios where id=?","COL",$portfolio); };
	if ($@) {
		return (undef,$@);
	} else {
		return ($cash[0],$@);
	}
}

sub GetPortfolioName {
	my ($portfolio) = @_;
	my @name;
	eval { @name=ExecSQL($dbuser,$dbpasswd, "select name from pm_portfolios where id=?","COL",$portfolio); };
	if ($@) {
		return (undef,$@);
	} else {
		return ($name[0],$@);
	}
}

sub PlotHistory {
	my ($symbol,$from,$to) = @_;
	my @rows;
	eval { @rows = ExecSQL($dbuser,$dbpasswd,"select timestamp, close from (select * from cs339.StocksDaily union select * from pm_new_data) t where symbol=? and timestamp>=? and timestamp<=? order by timestamp","2D",$symbol,$from,$to); };
	if ($@ || !@rows) {
		return 1;
	}

#
# This is how to drive gnuplot to produce a plot
# The basic idea is that we are going to send it commands and data
# at stdin, and it will print the graph for us to stdout
#
#
  	open(GNUPLOT,"| gnuplot") or die "Cannot run gnuplot";
  
  	print GNUPLOT "set term png\n";           # we want it to produce a PNG
  	print GNUPLOT "set output \"$symbol\_$from\_$to.png\"\n";             # output the PNG to stdout
  	print GNUPLOT "plot '-' using 1:2 with linespoints\n"; # feed it data to plot
  	foreach my $r (@rows) {
   		 print GNUPLOT $r->[0], "\t", $r->[1], "\n";
  	}
  	print GNUPLOT "e\n"; # end of data

  #
  # Here gnuplot will print the image content
  #

 	 close(GNUPLOT);
	return 0;
}

sub PlotPredict {
	my ($symbol,$from,$to) = @_;
	my $recent = GetRecentTime($symbol);
	my $interval = $to - $from;
	my $total_len = $recent + $interval;
	my @all =  `time_series_symbol_project.pl $symbol $total_len AWAIT 200 AR 16`;
	my @predictions;
	for (my $i=$#all+1-$total_len; $i<$#all+1; $i++) {
		push(@predictions,$all[$i]);
	}
	print "<pre>@predictions</pre>";
}

sub DepositCash {
	my ($portfolio, $deposit) = @_;
	my ($curr_amnt, $err) = GetPortfolioCash($portfolio);
	if ($err) {
		return $err;
	}
	else {
		my $new_amnt = $curr_amnt + $deposit;
		eval { ExecSQL($dbuser,$dbpasswd, "update pm_portfolios set cash=? where id=?",undef,$new_amnt,$portfolio); };
		if ($@) {
			return $@;
		} else {
			return undef;
		}
	}
}

sub WithdrawCash {
	my ($portfolio, $withdrawal) = @_;
	my ($curr_amnt, $err) = GetPortfolioCash($portfolio);
	if ($err) {
		return $err;
	} else {
		my $new_amnt = $curr_amnt - $withdrawal;
		if ($new_amnt < 0) {
			return "you do not have sufficient funds.";
		}
		eval { ExecSQL($dbuser,$dbpasswd, "update pm_portfolios set cash=? where id=?",undef,$new_amnt,$portfolio); };
		if ($@) {
			return $@;
		} else {
			return undef;
		}
	}
}


sub BuyShares {
	my ($id, $symbol, $shares, $price) = @_;
	my $new_shares;
	my ($balance, $err) = GetPortfolioCash($id);
	my $cost = $shares*$price;
	if ($cost > $balance) {
		return "you do not have sufficient funds.";
	}
	my @curr_shares;
	eval { @curr_shares=ExecSQL($dbuser,$dbpasswd, "select shares from pm_portfolio_contents where pid=? and symbol=?","COL",$id,$symbol); };
	if ($@) {
		return $@;
	}
	if (@curr_shares) {
		$new_shares = $curr_shares[0] + $shares;
		eval { ExecSQL($dbuser,$dbpasswd, "update pm_portfolio_contents set shares=? where pid=? and symbol=?",undef,$new_shares,$id,$symbol); };
		if ($@) {
			return $@;
		}
	} else {
		eval { ExecSQL($dbuser,$dbpasswd, "insert into pm_portfolio_contents (pid,symbol,shares) values(?,?,?)",undef,$id,$symbol,$shares); };
		if ($@) {
			return $@;
		}
	} 
	my $error = WithdrawCash($id,$cost);
	if ($error) {
		return $error;
	}
	return undef;
}


sub AddInformation {
	my ($symbol,$open,$close,$low,$high,$volume,$date) = @_;
	eval { ExecSQL($dbuser,$dbpasswd, "insert into pm_new_data (symbol,timestamp,open,low,high,close,volume) values(?,?,?,?,?,?,?)",undef,$symbol,$date,$open,$low,$high,$close,$volume); };
	if ($@) {
		return $@;
	} else {
		return undef;
	}
}


sub GetCOV {
	my ($symbol,$from,$to) = @_;
	my @info;
	eval { @info=ExecSQL($dbuser,$dbpasswd, "select avg(close), stddev(close) from (select * from cs339.StocksDaily union select * from pm_new_data) t where symbol=? and timestamp>=? and timestamp<=?",undef,$symbol,$from,$to); };
	if ($@) {
		return (undef,$@);
	}
	my $mean = $info[0]->[0];
	my $stddev = $info[0]->[1];
	my $cov = $stddev/$mean;
	return ($cov,$@);
}

sub GetBeta {
	my ($symbol,$from,$to) = @_;
  	my $s1=$symbol;
	my @rand_symbols;
	for (my $i=0; $i<5; $i++) {
		my ($rand) = ExecSQL($dbuser,$dbpasswd,"select symbol from (select symbol from cs339.StocksSymbols order by dbms_random.value) where rownum=1","ROW");
		push(@rand_symbols, $rand);
	}
    	my $covar;
	my $corrcoeff;
		#first, get means and vars for the individual columns that match
    
    	my $sql = "select count(*),avg(l.close),stddev(l.close),avg(r.close),stddev(r.close) from (select * from cs339.StocksDaily union select * from pm_new_data) l join (select timestamp,sum(close) close from (select * from (select * from cs339.StocksDaily union select * from pm_new_data) where symbol in (?,?,?,?,?)) group by timestamp)  r on l.timestamp= r.timestamp where l.symbol='$s1'";
    	$sql.= " and l.timestamp>=$from" if $from;
    	$sql.= " and l.timestamp<=$to" if $to;
    
    	my ($count, $mean_f1,$std_f1, $mean_f2, $std_f2) = ExecSQL($dbuser,$dbpasswd,$sql,"ROW",@rand_symbols);
    	
    		#skip this pair if there isn't enough data

    	if ($count<30) { # not enough data
    		return "NODAT";
    	} else {
      
     		 #otherwise get the covariance
     		$sql = "select avg((l.close - $mean_f1)*(r.close - $mean_f2)) from (select * from cs339.StocksDaily union select * from pm_new_data) l join (select timestamp,sum(close) close from (select * from (select * from cs339.StocksDaily union select * from pm_new_data) where symbol in (?,?,?,?,?)) group by timestamp) r on  l.timestamp=r.timestamp where l.symbol='$s1'";
     		$sql.= " and l.timestamp>= $from" if $from;
     		$sql.= " and l.timestamp<= $to" if $to;
     		($covar) = ExecSQL($dbuser,$dbpasswd,$sql,"ROW",@rand_symbols);
		#and the correlationcoeff
		$corrcoeff = $covar/($std_f1*$std_f2);
		return $corrcoeff;
	}	
}


sub SellShares {
	my ($id, $symbol, $shares, $price) = @_;
	my $value = $shares*$price;
	my $new_shares;
	my @curr_shares;
	eval { @curr_shares=ExecSQL($dbuser,$dbpasswd, "select shares from pm_portfolio_contents where pid=? and symbol=?","COL",$id,$symbol); };
	if ($@) {
		return $@;
	}
	$new_shares = $curr_shares[0] - $shares;
	if ($new_shares < 0) {
		return "you do not have sufficient shares.";
	}
	if ($new_shares == 0) {
		eval { ExecSQL($dbuser,$dbpasswd, "delete from pm_portfolio_contents where pid=? and symbol=?",undef,$id,$symbol); };
		if ($@) {
			return $@;
		}
	} else {
		eval { ExecSQL($dbuser,$dbpasswd, "update pm_portfolio_contents set shares=? where pid=? and symbol=?",undef,$new_shares,$id,$symbol); };
		if ($@) {
			return $@;
		}
	}
	my $error = DepositCash($id,$value);
	if ($error) {
		return $error;
	}
	return undef;
}

sub GetStocks {
	my ($portfolio) = @_;
	my @stocks;
	eval{ @stocks=ExecSQL($dbuser,$dbpasswd, "select symbol, shares from pm_portfolio_contents where pid=?",undef,$portfolio); };
	if ($@) {
		return (undef,$@);
	} else {
		return (@stocks,$@);
	}
}


#
#select t.symbol, t.open, t.close from cs339.StocksDaily t inner join (select symbol, max(timestamp) as max_date from cs339.StocksDaily where symbol='AAPL' group by symbol) a on a.symbol = t.symbol and a.max_date = t.timestamp;
#
#
#

sub GetRecentTime {
	my ($symbol) = @_;
	my @recent;
	@recent = ExecSQL($dbuser,$dbpasswd, "select max(timestamp) from (select * from cs339.StocksDaily union select * from pm_new_data) where symbol=?","COL",$symbol);
	return $recent[0];
}

sub GetRecentClose {
	my ($symbol) = @_;
	my @old_close;
	eval { @old_close = ExecSQL($dbuser,$dbpasswd, "select t.close from cs339.StocksDaily t inner join (select symbol, max(timestamp) as max_date from cs339.StocksDaily where symbol=? group by symbol) a on a.symbol = t.symbol and a.max_date = t.timestamp","COL",$symbol); };
	if ($@) {
		return (undef,$@);
	} else {
		my @new_close;
		eval { @new_close = ExecSQL($dbuser,$dbpasswd, "select t.close from pm_new_data t inner join (select symbol, max(timestamp) as max_date from pm_new_data where symbol=? group by symbol) a on a.symbol = t.symbol and a.max_date = t.timestamp","COL",$symbol); };
		if ($@) {
			return (undef,$@);
		} else {
			if ($new_close[0] > $old_close[0]) {
				return ($new_close[0],$@);
			}
			return ($old_close[0],$@);
		}
	}
}

sub Register {
	eval { ExecSQL($dbuser,$dbpasswd, "insert into pm_users (name,password) values (?,?)", undef, @_); };
	return $@; 
}

sub GetPortfolios {
	my ($user) = @_;
	my @portfolios;
	eval {@portfolios=ExecSQL($dbuser,$dbpasswd,  "select id from pm_portfolios where username=?","COL",$user);};
	if ($@) {
		return (undef,$@);
	} else {
		return (@portfolios,$@);
	}
}



sub ValidUser {
  my ($user,$password)=@_;
  my @col;
  eval {@col=ExecSQL($dbuser,$dbpasswd, "select count(*) from pm_users where name=? and password=?","COL",$user,$password);};
  if ($@) { 
    return 0;
  } else {
    return $col[0]>0;
  }
}

#
# Given a list of scalars, or a list of references to lists, generates
# an html table
#
#
# $type = undef || 2D => @list is list of references to row lists
# $type = ROW   => @list is a row
# $type = COL   => @list is a column
#
# $headerlistref points to a list of header columns
#
#
# $html = MakeTable($id, $type, $headerlistref,@list);
#
sub MakeTable {
  my ($id,$type,$headerlistref,@list)=@_;
  my $out;
  #
  # Check to see if there is anything to output
  #
  if ((defined $headerlistref) || ($#list>=0)) {
    # if there is, begin a table
    #
    $out="<table id=\"$id\" border>";
    #
    # if there is a header list, then output it in bold
    #
    if (defined $headerlistref) { 
      $out.="<tr>".join("",(map {"<td><b>$_</b></td>"} @{$headerlistref}))."</tr>";
    }
    #
    # If it's a single row, just output it in an obvious way
    #
    if ($type eq "ROW") { 
      #
      # map {code} @list means "apply this code to every member of the list
      # and return the modified list.  $_ is the current list member
      #
      $out.="<tr>".(map {defined($_) ? "<td>$_</td>" : "<td>(null)</td>" } @list)."</tr>";
    } elsif ($type eq "COL") { 
      #
      # ditto for a single column
      #
      $out.=join("",map {defined($_) ? "<tr><td>$_</td></tr>" : "<tr><td>(null)</td></tr>"} @list);
    } else { 
      #
      # For a 2D table, it's a bit more complicated...
      #
      $out.= join("",map {"<tr>$_</tr>"} (map {join("",map {defined($_) ? "<td>$_</td>" : "<td>(null)</td>"} @{$_})} @list));
    }
    $out.="</table>";
  } else {
    # if no header row or list, then just say none.
    $out.="(none)";
  }
  return $out;
}

sub CreateMatrix {
	my $docorrcoeff = 1;
	my %covar;
	my %corrcoeff;
	my $s1;
	my $s2;
	my ($from,$to,@symbols) = @_;
	for (my $i=0;$i<=$#symbols;$i++) {
  		$s1=$symbols[$i];
  		for (my $j=$i; $j<=$#symbols; $j++) {
    			$s2=$symbols[$j];
    
		#first, get means and vars for the individual columns that match
    
    			my $sql = "select count(*),avg(l.close),stddev(l.close),avg(r.close),stddev(r.close) from (select * from cs339.StocksDaily union select * from pm_new_data) l join (select * from cs339.StocksDaily union select * from pm_new_data) r on l.timestamp= r.timestamp where l.symbol='$s1' and r.symbol='$s2'";
    			$sql.= " and l.timestamp>=$from" if $from;
    			$sql.= " and l.timestamp<=$to" if $to;
    
    			my ($count, $mean_f1,$std_f1, $mean_f2, $std_f2) = ExecSQL($dbuser,$dbpasswd,$sql,"ROW");
    
    		#skip this pair if there isn't enough data

    			if ($count<30) { # not enough data
    				$covar{$s1}{$s2}='NODAT';
    				$corrcoeff{$s1}{$s2}='NODAT';
    			} else {
      
     		 #otherwise get the covariance

     				 $sql = "select avg((l.close - $mean_f1)*(r.close - $mean_f2)) from (select * from cs339.StocksDaily union select * from pm_new_data) l join (select * from cs339.StocksDaily union select * from pm_new_data) r on  l.timestamp=r.timestamp where l.symbol='$s1' and r.symbol='$s2'";
     				 $sql.= " and l.timestamp>= $from" if $from;
     				 $sql.= " and l.timestamp<= $to" if $to;

     				 ($covar{$s1}{$s2}) = ExecSQL($dbuser,$dbpasswd,$sql,"ROW");

		#and the correlationcoeff
	
				      $corrcoeff{$s1}{$s2} = $covar{$s1}{$s2}/($std_f1*$std_f2);
			}
  		}
	}
  	print "<br>";
 	print "<table name=\"corrcoeff\" style=\"height:25\%;width:100\%\">";
	print "<caption>Correlation Coefficient Matrix</caption>";
	print "<tr>";
	print "<th></th>";
	for (my $i=0;$i<=$#symbols;$i++) {
		print "<th>$symbols[$i]</th>";
	}
	print "</tr>";
  	for (my $i=0;$i<=$#symbols;$i++) {
    		$s1=$symbols[$i];
		print "<tr>";
   	 	print "<td>$s1</td>";
    		for (my $j=0; $j<=$#symbols;$j++) {
			print "<td>";
      			if ($i>$j) {
        			print ".";
      			} else {
        			$s2=$symbols[$j];
				if ($corrcoeff{$s1}{$s2} eq "NODAT") {
					print "NODAT";
				} else {
					print substr($corrcoeff{$s1}{$s2},0,7);
				}
      			}
			print "</td>";
    		}
    		print "</tr>";
  	}
  	print "<br>";
 	print "<table name=\"covar\" style=\"height:25\%;width:100\%\">";
	print "<caption>Covariance Matrix</caption>";
	print "<tr>";
	print "<th></th>";
	for (my $i=0;$i<=$#symbols;$i++) {
		print "<th>$symbols[$i]</th>";
	}
	print "</tr>";
  	for (my $i=0;$i<=$#symbols;$i++) {
    		$s1=$symbols[$i];
		print "<tr>";
   	 	print "<td>$s1</td>";
    		for (my $j=0; $j<=$#symbols;$j++) {
			print "<td>";
      			if ($i>$j) {
        			print ".";
      			} else {
        			$s2=$symbols[$j];
				if ($covar{$s1}{$s2} eq "NODAT") {
					print "NODAT";
				} else {
					print substr($covar{$s1}{$s2},0,7);
				}
      			}
			print "</td>";
    		}
    		print "</tr>";
  	}
	
}


#
# Given a list of scalars, or a list of references to lists, generates
# an HTML <pre> section, one line per row, columns are tab-deliminted
#
#
# $type = undef || 2D => @list is list of references to row lists
# $type = ROW   => @list is a row
# $type = COL   => @list is a column
#
#
# $html = MakeRaw($id, $type, @list);
#
sub MakeRaw {
  my ($id, $type,@list)=@_;
  my $out;
  #
  # Check to see if there is anything to output
  #
  $out="<pre id=\"$id\">\n";
  #
  # If it's a single row, just output it in an obvious way
  #
  if ($type eq "ROW") { 
    #
    # map {code} @list means "apply this code to every member of the list
    # and return the modified list.  $_ is the current list member
    #
    $out.=join("\t",map { defined($_) ? $_ : "(null)" } @list);
    $out.="\n";
  } elsif ($type eq "COL") { 
    #
    # ditto for a single column
    #
    $out.=join("\n",map { defined($_) ? $_ : "(null)" } @list);
    $out.="\n";
  } else {
    #
    # For a 2D table
    #
    foreach my $r (@list) { 
      $out.= join("\t", map { defined($_) ? $_ : "(null)" } @{$r});
      $out.="\n";
    }
  }
  $out.="</pre>\n";
  return $out;
}


sub ExecSQL {
  my ($user, $passwd, $querystring, $type, @fill) =@_;
  if ($debug) { 
    # if we are recording inputs, just push the query string and fill list onto the 
    # global sqlinput list
    push @sqlinput, "$querystring (".join(",",map {"'$_'"} @fill).")";
  }
  my $dbh = DBI->connect("DBI:Oracle:",$user,$passwd);
  if (not $dbh) { 
    # if the connect failed, record the reason to the sqloutput list (if set)
    # and then die.
    if ($debug) { 
      push @sqloutput, "<b>ERROR: Can't connect to the database because of ".$DBI::errstr."</b>";
    }
    die "Can't connect to database because of ".$DBI::errstr;
  }
  my $sth = $dbh->prepare($querystring);
  if (not $sth) { 
    #
    # If prepare failed, then record reason to sqloutput and then die
    #
    if ($debug) { 
      push @sqloutput, "<b>ERROR: Can't prepare '$querystring' because of ".$DBI::errstr."</b>";
    }
    my $errstr="Can't prepare $querystring because of ".$DBI::errstr;
    $dbh->disconnect();
    die $errstr;
  }
  if (not $sth->execute(@fill)) { 
    #
    # if exec failed, record to sqlout and die.
    if ($debug) { 
      push @sqloutput, "<b>ERROR: Can't execute '$querystring' with fill (".join(",",map {"'$_'"} @fill).") because of ".$DBI::errstr."</b>";
    }
    my $errstr="Can't execute $querystring with fill (".join(",",map {"'$_'"} @fill).") because of ".$DBI::errstr;
    $dbh->disconnect();
    die $errstr;
  }
  #
  # The rest assumes that the data will be forthcoming.
  #
  #
  my @data;
  if (defined $type and $type eq "ROW") { 
    @data=$sth->fetchrow_array();
    $sth->finish();
    if ($debug) {push @sqloutput, MakeTable("debug_sqloutput","ROW",undef,@data);}
    $dbh->disconnect();
    return @data;
  }
  my @ret;
  while (@data=$sth->fetchrow_array()) {
    push @ret, [@data];
  }
  if (defined $type and $type eq "COL") { 
    @data = map {$_->[0]} @ret;
    $sth->finish();
    if ($debug) {push @sqloutput, MakeTable("debug_sqloutput","COL",undef,@data);}
    $dbh->disconnect();
    return @data;
  }
  $sth->finish();
  if ($debug) {push @sqloutput, MakeTable("debug_sql_output","2D",undef,@ret);}
  $dbh->disconnect();
  return @ret;
}



######################################################################
#
# Nothing important after this
#
######################################################################

# The following is necessary so that DBD::Oracle can
# find its butt
#
BEGIN {
  unless ($ENV{BEGIN_BLOCK}) {
    use Cwd;
    $ENV{ORACLE_BASE}="/raid/oracle11g/app/oracle/product/11.2.0.1.0";
    $ENV{ORACLE_HOME}=$ENV{ORACLE_BASE}."/db_1";
    $ENV{ORACLE_SID}="CS339";
    $ENV{LD_LIBRARY_PATH}=$ENV{ORACLE_HOME}."/lib";
    $ENV{BEGIN_BLOCK} = 1;
    $ENV{PATH} = $ENV{PATH}.":.";
    exec 'env',cwd().'/'.$0,@ARGV;
  }
}


