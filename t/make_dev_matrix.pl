#!/usr/bin/perl -w

# $Id$

$DevMatrix = '../DeviceMatrix.txt';
$DevHTML   = 'DeviceMatrix.html';
$DevPNG    = 'DeviceMatrix.png';
$Tab = 2;

# Parse Data File
$matrix = parse_data($DevMatrix);

# Graph it for fun
eval "use GraphViz::Data::Structure;";
if ($@ or 1) {
    print "GraphViz::Data::Structure not installed.\n";
} else {
    my $gvds = GraphViz::Data::Structure->new($matrix);
    $gvds->graph()->as_png($DevPNG);
}

open (HTML, "> $DevHTML") or die "Can't open $DevHTML. $!\n";

foreach my $vendor (sort sort_nocase keys %$matrix){
    print "$vendor\n";

    my $defaults = $matrix->{$vendor}->{defaults};
    print_defaults($defaults,1);

    my $families = $matrix->{$vendor}->{families};
    foreach my $family (sort sort_nocase keys %$families ) {
        print "  $family\n";

        my $defaults = $families->{$family}->{defaults};
        print_defaults($defaults,2);

        my $models = $families->{$family}->{models};
        foreach my $model (sort sort_nocase keys %$models ){
            print "    $model\n";
            my $defaults = $models->{$model}->{defaults};
            print_defaults($defaults,3);
        }
    }
}

close (HTML) or die "Can't write $DevHTML. $!\n";

# Data Structures

# Matrix =
#   ( vendor => { families  => { family => family_hash },
#                  defaults => { cmd    => [values]    },
#               }
#   )

# Family Hash
#   ( models   => { model => model_hash },
#     defaults => { cmd   => [values]   }
#   )

# Model Hash
#   ( defaults => { cmd => [values] } )
sub parse_data {
    my $file = shift;
    my $Matrix;

    my @Lines;
    open (DM, "< $file") or die "Can't open $file. $!\n";
    {
        @Lines = <DM>;
    }
    close (DM);

    my ($device,$family,$vendor,$class);
    foreach my $line (@Lines){
        chomp($line);
        # Comments
        $line =~ s/#.*//;

        # Blank Lines
        next if $line =~ /^\s*$/;

        # Trim whitespace
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        my ($cmd,$value);
        if ($line =~ /^([a-z-_]+)\s*:\s*(.*)$/) {
            $cmd = $1;  $value = $2; 
        } else {
            print "What do i do with this line : $line \n";
            next;
        }

        # Set Class {vendor,family,device}
        if ($cmd eq 'device-vendor'){
            $vendor = $value;
            $family = $model = undef;
            $Matrix->{$vendor} = {} unless defined $Matrix->{$vendor};
            $class = $Matrix->{$vendor};
            next;
        }

        if ($cmd eq 'device-family'){
            $family = $value;
            $model = undef;
            print "$family has no vendor.\n" unless defined $vendor;
            $Matrix->{$vendor}->{families}->{$family} = {} 
                unless defined $Matrix->{$vendor}->{families}->{$family};
            $class = $Matrix->{$vendor}->{families}->{$family};
            next;
        }   

        if ($cmd eq 'device') {
            $model = $value;
            print "$model has no family.\n" unless defined $family;
            print "$model has no vendor.\n" unless defined $vendor;
            $Matrix->{$vendor}->{families}->{$family}->{models}->{$model} = {} 
                unless defined $Matrix->{$vendor}->{families}->{$family}->{models}->{$model};
            $class = $Matrix->{$vendor}->{families}->{$family}->{models}->{$model};
            next;
        }

        # Store attribute
        push (@{$class->{defaults}->{$cmd}} , $value);
    }

    return $Matrix;
}

sub sort_nocase {
    return lc($a) cmp lc($b);
}

sub print_defaults {
    my $defaults = shift;
    my $level    = shift;
    foreach my $d (sort sort_nocase keys %$defaults) {
        foreach my $val (sort sort_nocase @{$defaults->{$d}}) {
            print ' ' x ($Tab*$level);
            print "$d : $val\n";
        }
    }
}
