##############################################################################
#
#   Description:    This is a library to facilitate writing Fvwm Modules in
#                   Perl 5. It is implemented as a compiled extension with
#                   both XS and Perl code. It uses the same interface names
#                   that were in the original fvwmmod.pl. It differs mainly in
#                   the storing and activation of event handlers, and the
#                   implementation of the defined constants. Each routine and
#                   significant variable or constant is documented at its
#                   definition.
#
#                   This is inspired by the file fvwmmod.pl from the 2.0.45
#                   distribution of fvwm. However, it no longer bears any
#                   resemblance to the old fvwmmod.
#
#                   This code bears the following copyright:
#
#                           (c)1997 Randy J. Ray <randy@byz.org>
#                           All Rights Reserved.
#
#                           This code is covered under the terms of the
#                           Artistic License that covers Perl 5. See the file
#                           ARTISTIC in your distribution of Perl 5 for
#                           details.
#
#   Functions:      AUTOLOAD
#                   P_LAZY_HANDLERS
#                   P_PACKET_PASSALL
#                   P_STRIP_NEWLINES
#                   new
#                   initModule
#                   sendInfo
#                   readPacket
#                   endModule
#                   eventLoop
#                   processPacket
#                   addHandler
#                   deleteHandler
#                   clearAllHandlers
#                   setOptions
#                   GetConfigInfo
#
##############################################################################

package X11::Fvwm;

require 5.002;

use strict;
use Carp;
use vars qw($VERSION $revision @ISA @EXPORT $AUTOLOAD);

use Exporter;
use DynaLoader;
use AutoLoader;
use IO::File;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(
             C_ALL
             C_FRAME
             C_ICON
             C_L1
             C_L2
             C_L3
             C_L4
             C_L5
             C_LALL
             C_NO_CONTEXT
             C_R1
             C_R2
             C_R3
             C_R4
             C_R5
             C_RALL
             C_ROOT
             C_SIDEBAR
             C_TITLE
             C_WINDOW
             F_ALL_COMMON_FLAGS
             F_BORDER
             F_CirculateSkip
             F_CirculateSkipIcon
             F_ClickToFocus
             F_DoesWmTakeFocus
             F_DoesWmDeleteWindow
             F_HintOverride
             F_ICON_MOVED
             F_ICON_OURS
             F_ICON_UNMAPPED
             F_ICONIFIED
             F_Lenience
             F_MAP_PENDING
             F_MAPPED
             F_MAXIMIZED
             F_MWMButtons
             F_MWMBorders
             F_NOICON_TITLE
             F_ONTOP
             F_PIXMAP_OURS
             F_RAISED
             F_SHAPED_ICON
             F_SHOW_ON_MAP
             F_STARTICONIC
             F_STICKY
             F_SUPPRESSICON
             F_SloppyFocus
             F_StickyIcon
             F_TITLE
             F_TRANSIENT
             F_VISIBLE
             F_WINDOWLISTSKIP
             HEADER_SIZE
             MAX_BODY_SIZE
             MAX_MASK
             MAX_PACKET_SIZE
             M_ADD_WINDOW
             M_CONFIGURE_WINDOW
             M_CONFIG_INFO
             M_DEFAULTICON
             M_DEICONIFY
             M_DESTROY_WINDOW
             M_DEWINDOWSHADE
             M_END_CONFIG_INFO
             M_END_WINDOWLIST
             M_ERROR
             M_FOCUS_CHANGE
             M_ICONIFY
             M_ICON_FILE
             M_ICON_LOCATION
             M_ICON_NAME
             M_LOWER_WINDOW
             M_MAP
             M_MINI_ICON
             M_NEW_DESK
             M_NEW_PAGE
             M_RAISE_WINDOW
             M_RES_CLASS
             M_RES_NAME
             M_STRING
             M_WINDOWSHADE
             M_WINDOW_NAME
             P_LAZY_HANDLERS
             P_PACKET_PASSALL
             P_STRIP_NEWLINES
             START_FLAG
            );

$VERSION = '0.3';
$revision = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/o);

#
# This AUTOLOAD is intended to facilitate the loading of constants from the XS
# code. If the requested name is not one of the constants, then the routine
# AutoLoader::AUTOLOAD is called instead, to handle the split-off perl 
# routines.
#
sub AUTOLOAD {
    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
        if ($! =~ /Invalid/) {
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        }
        else {
                croak "Your vendor has not defined X11::Fvwm macro $constname";
        }
    }
    $val =~ /^/o; $val = $';
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap X11::Fvwm $VERSION;

# Preloaded methods go here.
########################################################################
# P_...: fvwmperl specific constants
#
# Subroutine-style constant defs.
#
sub P_LAZY_HANDLERS  { 1 }
sub P_PACKET_PASSALL { 2 }
sub P_STRIP_NEWLINES { 4 }
sub P_ALL_OPTIONS    { P_LAZY_HANDLERS | P_PACKET_PASSALL | P_STRIP_NEWLINES }

########################################################################
#
# Package-global values:
#
# These are tables and such that are not going to be different from instance
# to instance.
#
# Defined event types that send textual data in the packet
$X11::Fvwm::txtTypes = &M_ERROR | &M_CONFIG_INFO | &M_STRING;
# Defined event types that send variable data
$X11::Fvwm::varTypes = &M_WINDOW_NAME | &M_ICON_NAME | &M_RES_CLASS |
                       &M_RES_NAME    | &M_ICON_FILE | &M_DEFAULTICON;
# Unpack formats for the various packet types
%X11::Fvwm::packetTypes = (
                           &M_NEW_PAGE,          "l5",
                           &M_NEW_DESK,          "l",

                           &M_ADD_WINDOW,        "l24",
                           &M_CONFIGURE_WINDOW,  "l24",
                           &M_LOWER_WINDOW,      "l3",
                           &M_RAISE_WINDOW,      "l3",
                           &M_DESTROY_WINDOW,    "l3",
                           &M_WINDOWSHADE,       "l3",
                           &M_DEWINDOWSHADE,     "l3",
                           &M_FOCUS_CHANGE,      "l5",
                           &M_ICONIFY,           "l7",
                           &M_ICON_LOCATION,     "l7",
                           &M_DEICONIFY,         "l3",
                           &M_MAP,               "l3",
                           &M_WINDOW_NAME,       "l3a*",
                           &M_ICON_NAME,         "l3a*",
                           &M_RES_CLASS,         "l3a*",
                           &M_RES_NAME,          "l3a*",
                           &M_ICON_FILE,         "l3a*",
                           &M_DEFAULTICON,       "l3a*",
                           &M_MINI_ICON,         "l6",

                           &M_END_WINDOWLIST,    "",
                           &M_ERROR,             "l3a*",
                           &M_STRING,            "l3a*",
                           &M_CONFIG_INFO,       "l3a*",
                           &M_END_CONFIG_INFO,   ""
                          );

1;

##############################################################################
#
#   Sub Name:       new
#
#   Description:    Constructor - create a new obj of class X11::Fvwm and set
#                   it up.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    This class
#                   %params   in      hash      Extra initialization data
#
#   Returns:        Success:    blessed ref
#                   Failure:    undef
#
##############################################################################
sub new
{
    my $class = shift;
    my %params = @_;
    my $self = {};

    $class = ref($class) || $class;

    bless $self, $class;

    require Config;
    $self->{intsize} = $Config::Config{intsize};

    #
    # instance parameters:
    #
    $self->{MASK} = (defined $params{MASK}) ? $params{MASK} : 0;
    (my $name = $0) =~ s|.*/||o;
    $self->{NAME} = (defined $params{NAME}) ? $params{NAME} : $name;

    # Hash table (keyed on event ID/mask) of handlers
    $self->{handlerTable} = {};
    # Hash table of module options, from Fvwm and the .fvwm(2)?rc file
    $self->{modOption} = {};
    # A flag to know when we've read the above:
    $self->{modOptionRead} = 0;
    # Set to 1 the first time Initodule is run. Allows users to skip explicitly
    # calling InitModule if the default parameters are usable.
    $self->{didInit} = 0;
    # Internal options. *Not* recommended that this automatically include 
    # P_LAZY_HANDLERS. Set that explicitly in your script if you want it.
    $self->{OPTIONS} = (defined $params{OPTIONS}) ? $params{OPTIONS} :
                                                    &P_STRIP_NEWLINES;

    # Default this to off. Set with the call to new(), or explicitly
    $self->{DEBUG} = (defined $params{DEBUG}) ? $params{DEBUG} : 0;

    # Give them a handle on the unpack formats
    $self->{packetTypes} = \%X11::Fvwm::packetTypes;

    $self->initModule($self->{MASK})
        if (defined $params{INIT} and $params{INIT});

    $self->getConfigInfo('-') if (defined $params{CONFIG} and $params{CONFIG});

    $self;
}

##############################################################################
#
# All of these next few methods have the same basic structure. They are for
# accessing the instance variables that are made available to the user. Each
# goes something like this:
#
#     $val = $self->method;   # Return the current value of $self->{METHOD}
#     $self->method($val);    # Set the value of $self->{METHOD} to $val
#
##############################################################################

sub mask
{
    # If they are setting the value, return the *old* value. This is so that
    # routines/callbacks/handlers can temporarily grab packets outside the
    # usual scope (like getConfigInfo).
    return ($_[0]->set_mask($_[1])) if (defined $_[1]);

    $_[0]->{MASK};
}

sub name
{
    $_[0]->{NAME} = $_[1] if (defined $_[1]);

    $_[0]->{NAME};
}

sub options
{
    $_[0]->{OPTIONS} = $_[1] if (defined $_[1]);

    $_[0]->{OPTIONS};
}

#
# This is so certain to be called, no sense in having it auto-split out
#
# Send a packet to Fvwm to set the mask that this module accepts
#
sub set_mask
{
    unless (@_ == 2)
    {
        carp "X11::Fvwm::set_mask requires a mask argument\n";
        return undef;
    }

    return undef unless $_[0]->{didInit};

    $_[0]->sendInfo(0, "Set_Mask $_[1]");
    # Preserve so that we can return the old value, in case the caller planned
    # on reverting the mask later on.
    my $old = $_[0]->{MASK};
    $_[0]->{MASK} = $_[1];
    $old;
}

__END__

##############################################################################
#
#   Sub Name:       initModule
#
#   Description:    Initialize ourselves with Fvwm. Set up the file des,
#                   parse/store any extra args, set the mask, etc.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      X11::Fvwm Object of this class
#                   $mask     in      scalar    Mask to use (will override
#                                                 mask param to new())
#
#   Returns:        Success:    list of (winID, context, args) or 1
#                   Failure:    0
#
##############################################################################
sub initModule
{
    my $self = shift;
    my $initMask = shift;

    return 1 if ($self->{didInit});

    my ($hwinId, @argv);
    my ($outFd, $inFd, $fvwmWinId, $fvwmContxt, $fvwmRcfile);

    @argv = @ARGV;

    @argv >= 5 || croak "$0 should only be run from fvwm/fvwm2.\n";
    ($outFd, $inFd, $fvwmRcfile, $hwinId, $fvwmContxt) = 
        splice(@argv, 0, 5);
    $self->{fvwmWinId} = hex $hwinId;
    $self->{fvwmContext} = $fvwmContxt;
    $self->{fvwmRcfile} = $fvwmRcfile;
    $self->{argv} = [@argv];

    $outFd =~ /(\d+)/o; $outFd = $1;
    $inFd =~ /(\d+)/o; $inFd = $1;
    $self->{OFD} = new IO::File ">&$outFd";
    $self->{IFD} = new IO::File "<&$inFd";
    $self->{OFD}->autoflush(1);
    $self->{IFD}->autoflush(1);

    $self->{handlerTable} = {};
    $self->{sentEndPkt} = 0;
    $self->{didInit} = 1;

    $self->set_mask((defined $initMask) ? $initMask : $self->{MASK});

    ($self->{fvwmWinId}, $self->{fvwmContext}, @argv);
}

##############################################################################
#
#   Sub Name:       sendInfo
#
#   Description:    Send a bit of data to Fvwm via the pre-opened interface.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $winid    in      scalar    Window being sent information
#                   $data     in      scalar    Textual data to send
#                   $cont     in      scalar    Optional continuation argument;
#                                                 if explicitly set as 0, then
#                                                 this packet is sent as the
#                                                 last packet. Fvwm will close
#                                                 the connection.
#
#   Returns:        Success:    1
#                   Failure:    0
#
##############################################################################
sub sendInfo
{
    my $self = shift;
    my ($winid, $data, $cont) = @_;

    my (@parts, $part);

    $self->initModule unless ($self->{didInit});

    croak "Wrong # args to sendInfo" if (@_ < 2 || @_ > 3);

    $cont = 1 unless (defined $cont);
    @parts = split(/,/, $data);

    for $part (@parts)
    {
        $len = length $part;
        $self->{OFD}->print(pack("lla${len}l",
                                 $winid, length $part, $part, 1));
    }
    unless ($cont)
    {
        $self->{sentEndPkt} = 1;
        $self->{OFD}->print(pack("lla3l", $winid, 3, 'Nop', 0));
    }

    1;
}

##############################################################################
#
#   Sub Name:       readPacket
#
#   Description:    Read a data packet from Fvwm via the fdes set up earlier.
#                   Currently, this blocks until data is available.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#
#   Returns:        Success:    list of ($len, $data, $type)
#                   Failure:    -1
#
##############################################################################
sub readPacket
{
    my $self = shift;

    my $header = '';
    my $packet = '';
    my ($got, $magic, $type, $len, $timestmp);

    $self->initModule unless ($self->{didInit});

    # header is sizeof(int) * HEADER_SIZE bytes long:
    $got = sysread($self->{IFD}, $header, $self->{intsize} * &HEADER_SIZE);
    return -1
        unless (defined $got and $got == ($self->{intsize} * &HEADER_SIZE));

    ($magic, $type, $len, $timestmp) = unpack(sprintf("L%d", &HEADER_SIZE),
                                              $header);
    croak "Bad magic number $magic" unless $magic == &START_FLAG;

    # $len is # words in packet, including header;
    # we need this as number of bytes.
    $len -= &HEADER_SIZE;
    $len *= $self->{intsize};

    if ($len > 0)
    {
        my $off = 0;

        until ($off == $len)
        {
            if (! defined($got = sysread($self->{IFD}, $packet, $len, $off)))
            {
                croak "$self->{NAME} process ($$) exiting due to read error\n";
            }
            $off += $got;
        }
    }

    $self->{lastPacket} = [$len, $packet, $type];

    ($len, $packet, $type);
}

##############################################################################
#
#   Sub Name:       endModule
#
#   Description:    Close off contact with Fvwm and clean up
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#
#   Returns:        Success:    1
#                   Failure:    0
#
##############################################################################
sub endModule
{
    my $self = shift;

    if ($self->{didInit})
    {
        $self->sendInfo(0, "Nop", 0) unless ($self->{sentEndPkt});
        close $self->{IFD};
        close $self->{OFD};
    }

    1;
}

##############################################################################
#
#   Sub Name:       eventLoop
#
#   Description:    Enter a loop which waits for packets and uses processPacket
#                   to route them. If Tk has been loaded and initialized, then
#                   we call Tk's MainLoop.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    0
#
##############################################################################
sub eventLoop
{
    my $self = shift;

    $self->initModule unless ($self->{didInit});

    while (1)
    {
        $self->processPacket($self->readPacket) || last;
    }
    $self->invokeHandler('EXIT');

    1;
}

##############################################################################
#
#   Sub Name:       processPacket
#
#   Description:    Process a packet returned from readPacket. Unpack the
#                   based on the known format for the given type, then dispatch
#                   the apropos event handlers with the packet data.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $len      in      scalar    Packet length, in ints (words)
#                   $packet   in      scalar    Packet data
#                   $type     in      scalar    Packet type (one of M_*)
#
#   Returns:        Success:    1
#                   Failure:    0
#
##############################################################################
sub processPacket
{
    my $self = shift;

    my ($len, $packet, $type) = @_;
    unless (defined $len)
    {
        #
        # No arguments were passed-- check on our instance variables for the
        # last packet read
        #
        ($len, $packet, $type) = @{$self->{lastPacket}};
    }
    return 0 if ($len < 0);

    $type &= &MAX_MASK;
    my @args = unpack($X11::Fvwm::packetTypes{$type}, $packet);
    # If packet is text-based, strip everything past the first null
    # byte (or newline)
    if ($type & $X11::Fvwm::txtTypes)
    {
        my $nlpat = ($self->{OPTIONS} & &P_STRIP_NEWLINES) ? "\n+" : "";
        $args[3] =~ s/$nlpat\0.*//g;
        @args = splice(@args, 0, 4)
            unless ($self->{OPTIONS} & &P_PACKET_PASSALL);
    }
    elsif ($type & $X11::Fvwm::varTypes)
    {
        $args[3] =~ s/\0.*//g;
    }

    #
    # Dispatch any handlers pertinent to this event-type.
    #
    my ($h_index, $handler, $stop);
    for $_ (sort { $a <=> $b } keys %{$self->{handlerTable}})
    {
        next if ($_ eq 'EXIT');
        if ($type & $_)
        {
            for $h_index (@{$self->{handlerTable}->{$_}})
            {
                next unless defined $h_index; # Catch those that were deleted
                $handler = $h_index->[0];
                $stop    = $h_index->[1];

                if ($stop)
                {
                    return 0 unless &$handler($self, $type, @args);
                }
                else
                {
                    &$handler($self, $type, @args);
                }
            }
        }
    }

    1;
}

####################################
#
# Handler maintenance routines:
#
##############################################################################
#
#   Sub Name:       addHandler
#
#   Description:    Add an event handler for the event types matching $mask.
#                   $mask may be the logical OR of several event types, should
#                   the handler be such that it handles multiples. $handler is
#                   a code reference; symbolic references are not (yet)
#                   supported. $stop is a boolean flag that marks whether
#                   an error code from this handler should prevent any
#                   subsequent handlers from processing the same packet (as
#                   routed by processPacket).
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $htype    in      scalar    Mask of one or more event types
#                                                 that this handles
#                   $handler  in      CODE      Ref to the routine that handles
#                                                 the event(s)
#                   $stop     in      scalar    Boolean that indicates if an
#                                                 error return from $handler
#                                                 should cause processPacket
#                                                 to break out of the loop.
#                                                 Defaults to 0 if 
#                                                 P_LAZY_HANDLERS is set.
#
#   Returns:        Success:    ident string for new handler
#                   Failure:    undef
#
##############################################################################
sub addHandler
{
    my $self = shift;

    my ($htype, $handler, $stop) = @_;
    my ($stop_on_fail, $h_index);

    if (defined $handler and ref($handler) eq "CODE")
    {
        if (exists $self->{handlerTable}->{$htype})
        {
            $h_index = scalar @{$self->{handlerTable}->{$htype}};
        }
        else
        {
            $h_index = 0;
            $self->{handlerTable}->{$htype} = []
        }
        $stop_on_fail = (defined $stop) ? $stop :
            ($self->{OPTIONS} & &P_LAZY_HANDLERS) ? 0 : 1;
        my @new_handler = ($handler, $stop_on_fail);
        $self->{handlerTable}->{$htype}->[$h_index] = \@new_handler;
        sprintf "%d %d", $htype, $h_index;
    }
    else
    {
        undef;
    }
}

##############################################################################
#
#   Sub Name:       deleteHandler
#
#   Description:    Delete the specified handler from the table. Uses the
#                   string returned by addHandler as an identifier. If passed
#                   '*', then completely wipe the table.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $which    in      scalar    Ident of handler to remove
#
#   Returns:        Success:    1
#                   Failure:    0
#
##############################################################################
sub deleteHandler
{
    my $self = shift;
    my $which = shift;

    if ($which eq '*')
    {
        $self->clearAllHandlers;
        1;
    }
    else
    {
        my ($htype, $h_index) = split(/ /, $which);

        if (defined $self->{handlerTable}->{$htype}->[$h_index])
        {
            $self->{handlerTable}->{$htype}->[$h_index] = undef;
            1;
        }
        else
        {
            0;
        }
    }
}

##############################################################################
#
#   Sub Name:       clearAllHandlers
#
#   Description:    Clear this object's table of event handlers.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#
#   Returns:        Success:    ref to new hash
#                   Failure:    dies
#
##############################################################################
sub clearAllHandlers
{
    my $self = shift;

    $self->{handlerTable} = {};
}

##############################################################################
#
#   Sub Name:       invokeHandler
#
#   Description:    Force invocation of a given handler with the arguments
#                   passed. Caller is responsible for ensuring argument
#                   validity. Duplicates the loop used in processPacket b/c
#                   I don't want to forcibly create a packet just to have it
#                   disassembled again.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $type     in      scalar    Type mask for which to execute
#                                                 handlers.
#                   @args     in      list      Arguments to be passed.
#
#   Returns:        Success:    1
#                   Failure:    0
#
##############################################################################
sub invokeHandler
{
    my ($self, $type, @args) = @_;

    my ($h_index, $handler, $stop);

    if ($type eq 'EXIT')
    {
        return 1 unless (defined $self->{handlerTable}->{EXIT});
        for $h_index (@{$self->{handlerTable}->{EXIT}})
        {
            next unless defined $h_index; # Catch those that were deleted
            $handler = $h_index->[0];

            &$handler($self, $type, @args);
        }

        return 1;
    }

    for (sort { $a <=> $b } keys %{$self->{handlerTable}})
    {
        if ($type & $_)
        {
            for $h_index (@{$self->{handlerTable}->{$_}})
            {
                next unless defined $h_index; # Catch those that were deleted
                $handler = $h_index->[0];
                $stop    = $h_index->[1];

                if ($stop)
                {
                    return 0 unless &$handler($type, @args);
                }
                else
                {
                    &$handler($type, @args);
                }
            }
        }
    }

    1;
}

####################################
# Convenience functions
##############################################################################
#
#   Sub Name:       setOptions
#
#   Description:    Set and/or clear the Perlish module options. See the
#                   'options' method for explicitly setting options.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $set      in      scalar    New mask to be added to
#                                                 current options. Defaults to
#                                                 none if undef.
#                   $clear    in      scalar    Mask to be removed from the
#                                                 current options. Defaults
#                                                 to 0 if not passed (or undef)
#                   $preserve in      ref       If passed, assumed to be a
#                                                 scalar ref into which the
#                                                 current options are saved
#
#   Returns:        Success:    new options set
#                   Failure:    undef
#
##############################################################################
sub setOptions
{
    my $self = shift;

    my ($set, $clear, $preserve) = @_;

    $$preserve = $self->{OPTIONS} if (defined $preserve);
    $set   = 0 unless defined $set;
    $clear = 0 unless defined $clear;

    $self->{OPTIONS} |= $set;
    $self->{OPTIONS} &= ~$clear;

    $self->{OPTIONS};
}

##############################################################################
#
#   Sub Name:       getConfigInfo
#
#   Description:    Get the configuration information from Fvwm and return it
#                   to the caller. Gets the information the first time called,
#                   or if '*refresh' is one of the parameters. Returns only
#                   those keys that contain the application name as a substring
#                   within them (taken from $self->{NAME}), unless '*all' is
#                   one of the parameters, or unless there are parameters that
#                   do not start with the *, in which case only those keys will
#                   be returned.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   @keys     in      list      Possible controls on data rtn
#
#   Returns:        Success:    hash
#                   Failure:    undef
#
##############################################################################
sub getConfigInfo
{
    my $self = shift;
    my @keys = @_;

    my ($name, $value, @args, $len, $packet, $type, %hash, %params);

    $self->{DEBUG} && print STDERR ">>> Entering getConfigInfo\n";

    #
    # Turn the "keys" whose first character is - into a referrable hash table
    # that we'll test later on. Then remove any of these from the @keys list.
    #
    for (@keys) { $params{lc $1}++ if /^-(\w+)/o }
    @keys = grep(! /^-/, @keys);

    #
    # NOTICE: This will be deprecated sometime around the first official
    #         release. It is being marked as deprecated for now, to give people
    #         time to change.
    #
    for (@keys)
    {
        if (/^\*(\w+)/o)
        {
            $params{lc $1}++;
            warn "Use of * to specify options to getConfigInfo deprecated. " .
                "Use -$1 instead.\n";
        }
    }
    @keys = grep(! /^\*/, @keys);

    if ($self->{DEBUG})
    {
        print STDERR "getConfigInfo options: ",
            join(' ', (sort keys %params)), "\n"
                if ((scalar keys %params) != 0);
        print STDERR "selection key(s) specified: ", join(' ', (sort @keys)),
            "\n"
                if (scalar @keys != 0);
    }

    if ((! $self->{modOptionRead}) || (exists $params{refresh}))
    {
        #
        # We need to either read the info or update it.
        #
        # First, we save the current mask, and set a new mask that only
        # accepts M_CONFIG_INFO and M_END_CONFIG_INFO
        #
        my $old_mask = $self->mask(&M_END_CONFIG_INFO | &M_CONFIG_INFO);
        $self->sendInfo(0, "Send_ConfigInfo");

        while (1)
        {
            ($len, $packet, $type) = $self->readPacket;
            last if ($type & &M_END_CONFIG_INFO);
            last if ($len < 0);
            next if (! ($type & &M_CONFIG_INFO));

            @args = unpack($X11::Fvwm::packetTypes{$type}, $packet);

            ($name, $value) = $args[3] =~ /^\*?(\w+)(.*)/o;
            next unless (defined $name and $name);
            $name =~ s/^\*//o;
            $value =~ s/\0.*//o;
            $value =~ s/^\s+//o;
            $self->{DEBUG} && print STDERR "$name :- $value\n";
            if (exists $self->{modOption}->{$name})
            {
                if (ref($self->{modOption}->{$name}) eq 'ARRAY')
                {
                    push(@{$self->{modOption}->{$name}}, $value);
                }
                else
                {
                    my $tmp = [];

                    push(@{$tmp}, $self->{modOption}->{$name});
                    push(@{$tmp}, $value);
                    $self->{modOption}->{$name} = $tmp;
                }
            }
            else
            {
                $self->{modOption}->{$name} = $value;
            }
        }

        $self->mask($old_mask);
        $self->{modOptionRead} = 1;
    }

    %hash = ();

    if (exists $params{all})
    {
        %hash = %{$self->{modOption}};
    }
    elsif (@keys)
    {
        for (@keys)
        {
            $hash{$_} = $self->{modOption}->{$_};
        }
    }
    else
    {
        my $name = $self->{NAME};

        for (keys %{$self->{modOption}})
        {
            $hash{$_} = $self->{modOption}->{$_} if (/\Q$name\E/);
        }
    }

    #
    # Did they request that the NAME portion be trimmed from hash keys?
    #
    if (exists $params{trimname})
    {
        my $name = $self->{NAME};
        my @namparam;
        if (@namparam = grep(/^name=/oi, keys %params))
        {
            $namparam[0] =~ /^name=(.*)$/oi;
            $self->{DEBUG} &&
                print STDERR "Getting params for $1 rather than $name\n";
            $name = $1;
        }

        for my $key (keys %hash)
        {
            next unless ($key =~ /^\Q$name\E(.*)/);
            $hash{$1} = $hash{$key};
            delete $hash{$key};
        }
    }

    #
    # Did they ask for case-insensitivity?
    #
    if (exists $params{nocase})
    {
        for my $key (keys %hash)
        {
            next if ($key eq lc $key);
            $hash{lc $key} = $hash{$key};
            delete $hash{$key};
        }
    }

    $self->{DEBUG} && print STDERR "<<< Leaving getConfigInfo\n";

    %hash;
}

=head1 NAME

X11::Fvwm - Perl extension for the Fvwm2 X11 Window Manager

=head1 SYNOPSIS

    use X11::Fvwm;

    $handle = new X11::Fvwm;

    $handle->initModule;

    $handle->addHandler(M_CONFIGURE_WINDOW, \&configure_a_window);
    $handle->addHandler(M_CONFIG_INFO, \&some_other_sub);

    $handle->eventLoop;

    $handle->endModule;

=head1 DESCRIPTION

The B<X11::Fvwm> package is designed to provide access via Perl 5 to the
module API of Fvwm 2. This code is based upon Fvwm 2.0.45 beta.

The most common track to interfacing with Fvwm is to create an object of the
B<X11::Fvwm> class, and use it to create/destroy event handlers, and catch and
route such events from Fvwm. Event handlers can be tied to specific event
types, or given masks that include multiple events, for which the handler
would be passed the data for any of the events it accepts.

=head1 Exported constants

The following constants are exported automatically by B<X11::Fvwm>. Most
of these are defined either in the I<modules.tex> file that is part of the
B<docs/> directory in the fvwm distribution, or within the code itself
(particularly the files C<fvwm.h> and C<module.h> in the actual source
directory):

    C_ALL
    C_FRAME
    C_ICON
    C_L1
    C_L2
    C_L3
    C_L4
    C_L5
    C_LALL
    C_NO_CONTEXT
    C_R1
    C_R2
    C_R3
    C_R4
    C_R5
    C_RALL
    C_ROOT
    C_SIDEBAR
    C_TITLE
    C_WINDOW
    F_ALL_COMMON_FLAGS
    F_BORDER
    F_CirculateSkip
    F_CirculateSkipIcon
    F_ClickToFocus
    F_DoesWmTakeFocus
    F_DoesWmDeleteWindow
    F_HintOverride
    F_ICON_MOVED
    F_ICON_OURS
    F_ICON_UNMAPPED
    F_ICONIFIED
    F_Lenience
    F_MAP_PENDING
    F_MAPPED
    F_MAXIMIZED
    F_MWMButtons
    F_MWMBorders
    F_NOICON_TITLE
    F_ONTOP
    F_PIXMAP_OURS
    F_RAISED
    F_SHAPED_ICON
    F_SHOW_ON_MAP
    F_STARTICONIC
    F_STICKY
    F_SUPPRESSICON
    F_SloppyFocus
    F_StickyIcon
    F_TITLE
    F_TRANSIENT
    F_VISIBLE
    F_WINDOWLISTSKIP
    HEADER_SIZE
    MAX_BODY_SIZE
    MAX_MASK
    MAX_PACKET_SIZE
    M_ADD_WINDOW
    M_CONFIGURE_WINDOW
    M_CONFIG_INFO
    M_DEFAULTICON
    M_DEICONIFY
    M_DESTROY_WINDOW
    M_DEWINDOWSHADE
    M_END_CONFIG_INFO
    M_END_WINDOWLIST
    M_ERROR
    M_FOCUS_CHANGE
    M_ICONIFY
    M_ICON_FILE
    M_ICON_LOCATION
    M_ICON_NAME
    M_LOWER_WINDOW
    M_MAP
    M_MINI_ICON
    M_NEW_DESK
    M_NEW_PAGE
    M_RAISE_WINDOW
    M_RES_CLASS
    M_RES_NAME
    M_STRING
    M_WINDOWSHADE
    M_WINDOW_NAME
    P_LAZY_HANDLERS
    P_PACKET_PASSALL
    P_STRIP_NEWLINES
    START_FLAG

See L</CONSTANTS AND FLAGS> below for short definitions of these.

=head1 METHODS

Object manipulation is provided via these methods. C<$self> is assumed to
be an object of this class, and all methods aside from B<new> are assumed
to be prefixed as B<$self-E<gt>method>.

=over 8

=item new

$self = new X11::Fvwm %params

Create and return an object of the B<X11::Fvwm> class. The return value is
the blessed reference. Any combination of C<INIT>, C<CONFIG>, C<MASK>,
C<NAME>, C<OPTIONS> and C<DEBUG> may be passed in with corresponding values
to specify certain parameters at creation time. Each of these are treated
as key/value pairs, so even options such as C<INIT> that are only meaningful
if set to "1" still must have that value.

If C<INIT> is specified and evaluates to true, C<initModule> is run.

If C<CONFIG> is specified and evaluates to true, C<getConfigInfo> is run,
but no values are returned from it. It is run only to warm up the internal
cache.

If C<MASK> is specified, the value passed in is sent to I<Fvwm> as the
packet mask this application requires.

If C<NAME> is specified, it is stored as the internal name for the application,
which is used primarily for selecting configuration options intended for the
running application.

If C<OPTIONS> is specified, it is stored as the Perl options for the object.
Otherwise, the options default to C<P_STRIP_NEWLINES>.

If C<DEBUG> is specified and evaluates to true, debugging is enabled for this
object.

=item mask

$old_mask = $self->mask($new_mask)

Get or set the current mask for this object. If called with no argument, then
the current value of the mask is returned. Otherwise, the single argument is
sent to I<Fvwm> as a new mask request.

=item name

$name = $self->name($new_name)

Get or set the name by which the running object expects to br identified. This
defaults to the last element of C<$0>, the script name, but they do not have
to be identical. Do understand that I<Fvwm> will attempt some communications
based on the name by which it knows the running module. B<name()> has no
bearing on this. This is the value used for pattern matching if the
B<getConfigInfo> method is called with the C<*trimname> option.

=item options

$opts = $self->options($new_options)

Get or set the Perl-level options that this object uses. These are the
C<P_*> constants. See also the I<setOptions> method, described below.

=item initModule

$self->initModule($mask)

Initialize this object with respect to the I<Fvwm> communication streams.
Takes the I<Fvwm>-related items out of the arguments list and leaves any
remaining arguments in an instance variable called C<argv>. The read and
write pipes are recorded for use by the communication methods, and the
configuration file, window ID and context are stored on instance variables
as well (see L</Instance Variables>).

B<initModule> takes one optional argument, a packet mask to send after the
communications pipes are set up. If passed, it will override any value that
may have been specified in the call to B<new>. If not specified, then the
value from B<new> is used, and if there was no specific mask given to C<new>
then no mask is sent, meaning that the object will get every packet sent out
by I<Fvwm>.

=item sendInfo

$self->sendInfo($win_id, $data)

Send to I<Fvwm> a data packet with possible window specification. The
contents of C<$data> will be sent, encoded as I<Fvwm> specifies. C<$win_id>
may be 0, in which case I<Fvwm> handles the transaction itself, unless the
transaction is in fact window-specific, in which case I<Fvwm> prompts the
user to select a target window.

=item readPacket

$self->readPacket()

Read a data packet from I<Fvwm> via the input handle the module received
at start-up. Returns the triple I<($len, $packet, $type)>, and also stores
this on the instance variable C<lastPacket>. This call will block until
there is data available on the pipe to be read.

=item processPacket

$self->processPacket($len, $packet, $type)

Breaks down the contents of C<$packet> based on C<$type>. Dispatches all
packet handlers that accept packets of type C<$type>, passing as arguments
C<$type> follwed by the contents of the packet itself. If C<$len> is C<undef>,
then the triple stored in C<lastPacket> is used. If C<$len> is equal to -1,
then this method immediately returns a value of 0.

If the I<$stop> flag passed when a handler was created (see B<addHandler>)
was true, then a false (zero) return value from the handler causes
B<processPacket> to return 0. Setting the option C<P_LAZY_HANDLERS> causes
all handlers created to set their I<stop> value to 0.

The execution of handlers is done in a two-stage loop, the first being by
looping incrementally through all the masks for which known handlers
exist and secondly in the order in which handlers were added for a given
mask. If two handlers are created for the packet C<M_ERROR> and one for the
combination of C<M_ERROR> and C<M_STRING>, then the two for C<M_ERROR> alone
will be evaluated first, in the order in which they were created. Afterwards,
the one handler will be executed. This is because the value of C<M_ERROR>
and C<M_STRING> combined will be greater than C<M_ERROR> alone.

In general, if multiple handlers are going to be assigned to a given packet
type, they should be as independant of each other as possible, and reliance
on execution order should be avoided.

=item addHandler

$new_id = $self->addHandler($mask, $reference)

Add a new handler routine to the internal table, set to be called for any
packets whose type is included in C<$mask>. The mask argument may contain
more than one of the known packet types (see L</Packet Types>), or may be
the special string B<EXIT>. All handlers of type B<EXIT> are called
by B<eventLoop> at termination (or may be explicitly called within signal
catchers and the like with B<invokeHandler>). Others are called when a
packet of the flagged type arrives.

The return value from B<addHandler> is an identifier into the internal table
kept and tracked by the B<X11::Fvwm> object. This identifier is used in the
case where a handler should be deleted. The return value itself should not
be directly used, as its format is internal and does not give any indication
of execution priority.

The second argument to B<addHandler> is a reference to a subroutine (or
closure). This is the code (or I<callback>, if you prefer) that will be
executed with the packet contents as arguments. Every handler gets arguments
of the form:

        ($self, $type, $id, $frameid, $ptr, [, @args])

where C<$type> is the packet type itself (or B<EXIT>), C<$id> is the X
Windows window ID of the application main window, C<$frameid> is the X
window ID of the frame created by I<Fvwm> to house the window decorations,
and C<$ptr> is an index into the internal database that I<Fvwm> maintains for
all managed windows. C<$self> is the reference to the B<X11::Fvwm> object
that invoked the B<addHandler> method, allowing the routine access to the
instance variables.
If the packet, by definition, has additional arguments,
these follow after the initial four, in the order described by the module
API documentation packaged with I<Fvwm>. All packets, however, contain
at least these three initial values (the C<$type> argument is provided
by B<processPacket> for the sake of handlers written to manage multiple
packet types).

The C<$ptr> argument is guaranteed to be unique for all windows currently
managed. It can prove useful as an index itself (see the B<PerlTkWL> sample
application, which uses this value in such a way).

The B<addHandler> method does not allow or support symbolic references to
subroutines.

=item deleteHandler

$self->deleteHandler($id)

Delete the specified handler from the internal table. C<$id> must be a
value returned from an earlier call to B<addHandler>.

=item invokeHandler

$self->invokeHandler($type, @args)

Force the execution of all handlers that would trigger on a packet of type
C<$type>. C<@args> will be passed to each called routine immediately
following C<$type> itself, as is the behavior of B<processPacket>.

=item setOptions

$new_opts = $self->setOptions($set, $clear, $preserve)

A more extensive way to set and clear Perl object options. All flags set
in the value C<$set> will be added to (via logical OR) the current options.
All flags in C<$clear> will be removed from the current options. If
C<$preserve> is passed, it is expected to be a scalar reference, and the
current options settings are stored in it before alteration. Either of
C<$set> or C<$clear> can be C<undef>, in which case they have no effect.
The return value is the new option set.

This differs from the I<options> method described earlier, which only
fetches or assigns the options, it does not allow for the detail provided
here.

=item getConfigInfo 

%hash = $self->getConfigInfo(@keys)

Fetch information from the running I<Fvwm> process through the configuration
interface. Configuration lines are those lines in the configuration file
that start with a leading B<*> character. The first time this method is
called, the module fetches all configuration information, discarding the
leading asterisk from the names. Specific values may be requested, or the
entire contents fetched. A module has access to all configuration data,
not just the lines that match the name of the program. The return value
is a hash table whose keys are the name part of the configuration lines
(sans asterisk) and whose values are the contents of the lines.

In addition to the configuration lines, I<Fvwm> also sends the following
parameters: C<IconPath>, C<PixmapPath>, C<ColorLimit> and C<ClickTime>.
These are also retrievable by those names.

The values in the optional arguments C<@keys> can be a specific name to look
up (or names), or any of the following special directives:

B<-refresh> forces B<getConfigInfo> to re-read the data from I<Fvwm>.

B<-all> causes the method to return the full configuration table, not just
those names that contain the module name as a substring of the configuration
item name (this value is taken from the B<NAME> instance variable).

B<-trimname> instructs the method to excise the module name (the value of
the B<NAME> instance variable) from any keys in the final return set that
contain the name as a substring. As an example, a module named B<TkWinList>
can get back names such as I<Foreground> rather than I<TkWinListForeground>.
Keys not containing the substring will not be affected.

If any specific keys are requested in B<@args>, then the returned hash table
only contains those keys which were in fact present in the internal table.
B<-trimname> can still be used to remove the module name from the keys.

If an option is intended to be lengthy and possibly span lines, multiple
occurances of that configuration name can appear in the configuration file.
In cases where the same name appears more than once, the value returned for
that key is an array reference rather than a scalar. The contents of the
referred array are all the values from the series of lines.

Again, the B<PerlTkWL> sample application utilizes these features, and may
be referenced for further information.

B<Note:> Alpha versions of this module used the asterisk (B<*>) to
specify directives to getConfigInfo. That has been deprecated with the
first beta release (0.3), and will be removed entirely in the first
official release.

=item eventLoop 

$self->eventLoop($top)

An endless loop is entered in which
B<readPacket> and B<processPacket> are called. When B<processPacket> indicates
a completion (by an exit code of zero), any EXIT handlers are called and the
module exits.

=item endModule

$self->endModule

Sends a final packet to I<Fvwm> indicating that the module is exiting, then
closes the input and output pipes.

=back

=head2 Instance Variables

In addition to the methods above, there are also several instance
variables available to the programmer. Not all of the instance variables
are intended to be accessed or altered by the programmer, but the ones in
the following listing are meant to be public:

=over 8

=item MASK

This is the current mask registered with Fvwm. Setting this does not
automatically set a new mask. Use the C<mask()> method above for that.

=item NAME

This is the current application name, for the purpose of associating
module configuration options. Set it with C<name()> described above.

=item OPTIONS

The current Perl-level module options. Can be tested against the C<P_*>
constants. Can be set with the either the B<setOptions> method or the
C<options> method, both described above.

=item DEBUG

A flag used to note when debugging information is requested. Can be used in
handler routines to supplement debugging, or set/unset as desired for
selective debugging.

=item fvwmWinId

The X window ID for the window from whose context the module was launched,
if applicable. If the module was not launced from the context of a specific
window, this value is zero.

=item fvwmContext

The actual context of the launch, if applicable. Can be compared against the
C<C_*> constants. Also set to zero if the module was not launched in context
of a specific window.

=item fvwmRcfile

The configuration file that I<Fvwm> read at its own start-up. In earlier
API models, the module was responsible for reading this file directly to
obtain configuration information. That is no longer necessary, but having
the path to the file handy may still be useful to some applications.

=item packetTypes

This is a reference to the internal hash-table of unpack formats used in
the processing of packet data. Most likely, a module developer will not need
this, as the handlers are invoked with the data already unpacked and sent as
subroutine arguments. However, some cases arise (such as the initialization
in the B<PerlTkWL> sample application) when it is necessary to talk to and
understand the results from Fvwm directly. Modify this at your own peril.

=item lastPacket

A list-reference containing the data from the most-recent packet read, as a
triple I<($len, $packet, $type)>. Will be undefined until the first packet
read.

=back

=head1 CONSTANTS AND FLAGS

The lines of communication between I<Fvwm> and the module are maintained
via the well-defined flags and constants from the header files in the
source. The following values are exported by default into the namespace of
the application or package using B<X11::Fvwm>. They are taken directly from
the header files, so should be portable across platforms:

=head2 Packet Types

Most of the packets have the same first three parameters as explained in the
definition of the B<addHandler> method. For this section, assume that C<$id>,
C<$frameid> and C<$ptr> have the same meaning as defined there.  Much of
this text is based on the file F<modules.tex> in the I<Fvwm> distribution.

=over 8

=item M_ADD_WINDOW

This packet is essentially identical to B<M_CONFIGURE_WINDOW> below, differing
only in that B<M_ADD_WINDOW> is sent once, when the window is created, and
the B<M_CONFIGURE_WINDOW> packet is sent when the viewport on the current
desktop changes, or when the size or location of the window is changed.
They contain 24 values. The first 3 identify the window, and the next twelve
identify the location and size, as described in the list below. The flags
field is an bitwise OR of the flags defined below in L</Flags>:

        Arg #        Usage
        
        0            $id
        1            $frameid
        2            $ptr
        3            X location of the window frame
        4            Y location of the window frame
        5            Width of the window frame (pixels)
        6            Height of the window frame (pixels)
        7            Desktop number
        8            Windows flags field
        9            Window Title Height (pixels)
        10           Window Border Width (pixels)
        11           Window Base Width (pixels) 
        12           Window Base Height (pixels)
        13           Window Resize Width Increment(pixels)
        14           Window Resize Height Increment (pixels)
        15           Window Minimum Width (pixels)
        16           Window Minimum Height (pixels)
        17           Window Maximum Width Increment(pixels)
        18           Window Maximum Height Increment (pixels)
        19           Icon Label Window ID, or 0
        20           Icon Pixmap Window ID, or 0
        21           Window Gravity
        22           Pixel value of the text color
        23           Pixel value of the window border color

=item M_CONFIGURE_WINDOW

Same structure and contents as B<M_ADD_WINDOW>.

=item M_CONFIG_INFO

I<Fvwm> records all configuration commands that it encounters which begins
with the character "B<*>". When the built-in command B<Send_ConfigInfo>
is invoked by a module, this entire list is transmitted to the module in
packets (one line per packet) of this type. The packet consists of three
zeros, followed by a variable length character string. In addition, the
B<PixmapPath>, B<IconPath>, B<ColorLimit> and B<ClickTime> parameters are
sent to the module.

=item M_DEFAULTICON

This packet identifies the default icon for the session. The first three
arguments are all zero, and the fourth is a text string containing the name
of the icon to use.

=item M_DEICONIFY

This packet contains the standard three arguments. It is sent whenever the
indicated window is de-iconified.

=item M_DESTROY_WINDOW

The three default arguments identify a window that was just destroyed, and
is no longer on the display.

=item M_DEWINDOWSHADE

The three default arguments identify a window that was just unshaded
(applicable only if window-shading was enabled in the configuration).

=item M_END_CONFIG_INFO

After I<Fvwm> sends all of its B<M_CONFIG_INFO> packets to a module, it
sends a packet of this type to indicate the end of the configuration
information. This packet contains no values.

=item M_END_WINDOWLIST

This packet is sent to mark the end of transmission in response to a
B<Send_WindowList> request. A module which requests B<Send_WindowList>, then
processes all packets received between the request and the B<M_END_WINDOWLIST>
will have a snapshot of the status of the desktop.

=item M_ERROR

When fvwm has an error message to report, it is echoed to the modules in
a packet of this type. This packet has 3 values, all zero, followed by a
variable length string which contains the error message. It does not have
the standard first three values.

=item M_FOCUS_CHANGE

This packet signifies that the window manager focus has changed. The first
three parameters are the common three. There are also a fourth and fifth
parameter, the pixel value of the window's text focus color and the window's
border focus color, respectively. If the window that now has the focus is not
a window recognized by I<Fvwm>, then only the first of these five values,
the X window ID, is set. The rest will be zeros.

=item M_ICONIFY

This packets contain 7 values. The first 3 are the usual identifiers, and the
next four describe the location and size of the icon window, as described
below. Note that B<M_ICONIFY> packets will be sent whenever a window is
first iconified, or when the icon window is changed via the B<XA_WM_HINTS>
in a property notify event. An B<M_ICON_LOCATION> packet will be sent when
the icon is moved.  If a window which has transients is iconified, then an
B<M_ICONIFY> packet is sent for each transient window, with the X, Y, width,
and height fields set to 0. This packet will be sent even if the transients
were already iconified. Note that no icons are actually generated for the
transients in this case.

        Arg #        Usage
        
        0            $id
        1            $frameid
        2            $ptr
        3            X location of the icon frame
        4            Y location of the icon frame
        5            Width of the icon frame (pixels)
        6            Height of the icon frame (pixels)

=item M_ICON_FILE

This packet has the three standard arguments identifying the window, then
a text string with the the name of the file used as the icon image. This
packet is sent only to identify the icon used by the module itself.

=item M_ICON_LOCATION

Similar to the B<M_ICONIFY> packet described earlier, this packet has the same
arguments in the same order. It is sent whenever the associated icon is moved.

=item M_ICON_NAME

This packet is like the B<M_RES_CLASS> and B<M_RES_NAME> packets. It contains
the usual three window identifiers, followed by a variable length character
string that is the icon name.

=item M_LOWER_WINDOW

The three default arguments identify a window that was just moved to the
bottom of the stacking order.

=item M_MAP

Contains the standard 3 values.  The packets are sent when a window is
mapped, if it is not being deiconified. This is useful to determine when
a window is finally mapped, after being added.

=item M_MINI_ICON

Not yet documented.

=item M_NEW_DESK

This packet type does not have the usual three leading arguments.  The body
of this packet consists of a single long integer, whose value is the number
of the currently active desktop. This packet is transmitted whenever the
desktop number is changed.

=item M_NEW_PAGE

These packets also differ from the standard in not having the usual first
three arguments. Instead, they contain 5 integers. The first two are the
X and Y coordinates of the upper left corner of the current viewport on
the virtual desktop. The third value is the number of the current desktop.
The fourth and fifth values are the maximum allowed values of the coordinates
of the upper-left hand corner of the viewport.

=item M_RAISE_WINDOW

The three default arguments identify a window that was just moved to the
top of the stacking order.


=item M_RES_CLASS

This packet contains the usual three window
identifiers, followed by a variable length character string.
The B<RES_CLASS> and B<RES_NAME> fields are fields in the
I<XClass> structure for the window. The B<RES_CLASS> and B<RES_NAME> packets
are sent on window creation and in response to a B<Send_WindowList> request
from a module.

=item M_RES_NAME

This packet is identical to B<M_RES_CLASS>, identifying instead the resource
name for the window.

=item M_STRING

Similar to the other text packets such as B<M_ICON_NAME> or B<M_RES_CLASS>,
this packet contains zeros for the first three arguments, and a variable-length
text string as its fourth. This is sent to all modules whose name matches
the name pattern from a B<SendToModule> command.

=item M_WINDOWSHADE

The three default arguments identify a window that was just shaded (applicable
only if window-shading was enabled in the configuration).

=item M_WINDOW_NAME

This packet is like the B<M_ICON_NAME>, B<M_RES_CLASS> and B<M_RES_NAME>
packets. It contains the usual three window
identifiers, followed by a variable length character string that is the
window name.

=back

=head2 Packet Values

These values are used in disassembling a raw packet into data that is then
passed to a handler. In general, a developer will not need these, as the
bulk of the work that they are used for occurs in B<readPacket>. They are
here for completeness, and in case an application does have a need.

=over 8

=item START_FLAG

This is the value that should be in the first word of the packet. It is
set to C<0xffffffff> (if the word size is 32 bits). If this is not the first
word in the packet, the packet cannot be considered usable.

=item HEADER_SIZE

The size, in words, of the header. This is used to separate the words that
comprise the header from the packet body.

=item MAX_BODY_SIZE

Maximum size of a packet body, in words.

=item MAX_MASK

A mask that matches all B<M_*> packet type values, useful as an operator to
a logical and.

=item MAX_PACKET_SIZE

Maximum packet size (in words), including both header and body.

=back

=head2 Context Specifiers

When a module is launched, one of the parameters passed on the command-line
is the context in which the module was started. This is stored on the
B<X11::Fvwm> object instance in the variable B<fvwmContext>. These flags can
be used in tests against this value to determine where the running module was
launched from.

=over 8

=item C_ALL

A mask that matches all B<C_*> flags. Useful as a logical and operand.

=item C_NO_CONTEXT

The module has no launch context. These are modules that are launched from
the configuration file as I<Fvwm> starts up.

=item C_ROOT

The module was launched from the root window (via PopUp menu or hot-key).

=item C_SIDEBAR

Launch was from the sidebar decorating an application.

=item C_TITLE

Lauch occurred from the titlebar itself (but not any of the buttons).

=item C_WINDOW

The module was launched from within the window of a running application.

=item C_FRAME

Launch was from the frame of a managed window.

=item C_ICON

Launch was from the icon of a managed application.

=item C_L1

The first (leftmost) button on the left of the titlebar.

=item C_L2

Second left-side button (to the right of C<C_L1>).

=item C_L3

Third left-side button (to the right of C<C_L2>).

=item C_L4

Fourth left-side button (to the right of C<C_L3>).

=item C_L5

Fifth left-side button (to the right of C<C_L4>).

=item C_LALL

A mask that matches any of the B<C_L[12345]> context flags.

=item C_R1

The first (rightmost) button on the right of the titlebar.

=item C_R2

Second right-side button (to the left of B<C_R1>).

=item C_R3

Third right-side button (to the left of B<C_R2>).

=item C_R4

Fourth right-side button (to the left of B<C_R3>).

=item C_R5

Fifth right-side button (to the left of B<C_R4>).

=item C_RALL

A mask that matches any of the B<C_R[12345]> context flags.

=back

=head2 Flags

These are the flags, from the file F<fvwm.h>, that are packed into the
I<FLAGS> value of B<M_ADD_WINDOW> and B<M_CONFIGURE_WINDOW> packets.
Unlike the other constants and flags used by the B<X11::Fvwm> module, these
have slightly different names than their native I<Fvwm> counterparts. This
is because the values in F<fvwm.h> have no distinct prefix, such as B<C_>
or B<M_>. So as to reduce the risk of name conflict, all of these flags
were given a prefix of B<F_>.

=over 8

=item F_ALL_COMMON_FLAGS

A mask covering the more commonly-used style flags:
B<F_STARTICONIC>, B<F_ONTOP>, B<F_STICKY>, B<F_WINDOWLISTSKIP>,
B<F_SUPPRESSICON>, B<F_NOICON_TITLE>, B<F_Lenience>, B<F_StickyIcon>,
B<F_CirculateSkipIcon>, B<F_CirculateSkip>, B<F_ClickToFocus>,
B<F_SloppyFocus>, B<F_SHOW_ON_MAP>.

=item F_BORDER

This window has a border drawn with it.

=item F_CirculateSkip

This window has the I<CirculateSkip> style property set.

=item F_CirculateSkipIcon

This window has the I<CirculateSkipIcon> style property set.

=item F_ClickToFocus

Whether the window focus style is I<ClickToFocus>.

=item F_DoesWmTakeFocus

Whether the C<_XA_WM_TAKE_FOCUS> property is set on the window.

=item F_DoesWmDeleteWindow

Whether the C<_XA_WM_DELETE_WINDOW> property is set on the window.

=item F_HintOverride

Not documented yet.

=item F_ICON_MOVED

Not documented yet.

=item F_ICON_OURS

The icon window was provided by I<Fvwm>, and should be freed by I<Fvwm>.

=item F_ICON_UNMAPPED

Not documented yet.

=item F_ICONIFIED

This window is currently iconified.

=item F_Lenience

Not documented yet.

=item F_MAP_PENDING

This application is still awaiting mapping.

=item F_MAPPED

This window (application) is mapped on the display.

=item F_MAXIMIZED

This window is currently maximized.

=item F_MWMButtons

This window has its style set to include MWM-ish buttons.

=item F_MWMBorders

This window has its style set to include MWM-ish borders.

=item F_NOICON_TITLE

This window will not have a title with its icon.

=item F_ONTOP

This window is set with the I<StaysOnTop> style setting, meaning that it will
always be raised over any windows that ubscure it, even partially (except
other I<StaysOnTop> windows).

=item F_PIXMAP_OURS

The pixmap used for the icon was loaded and provided by I<Fvwm>, and should
also be freed by I<Fvwm> when no longer needed.

=item F_RAISED

If it is a sticky window, this indicates whether or not it needs to be
raised.

=item F_SHAPED_ICON

The icon for this window is a shaped icon.

=item F_SHOW_ON_MAP

When this window is mapped, the desktop should switch to the apropos
quadrant and desk.

=item F_STARTICONIC

This window was instructed to start in an iconic state.

=item F_STICKY

This window is considered sticky.

=item F_SUPPRESSICON

This application should not be displayed when iconic.

=item F_SloppyFocus

This window responds to a focus style of I<SloppyFocus>.

=item F_StickyIcon

The icon for this window is considered sticky.

=item F_TITLE

This window is assigned a title bar.

=item F_TRANSIENT

This window is a transient window.

=item F_VISIBLE

Window is considered fully-visible (only obscuring should be windows that
are set to I<StaysOnTop>).

=item F_WINDOWLISTSKIP

This window should be skipped over in generated lists of windows.

=back

=head2 Perl Values

These are values that relate to the Perl objects directly. They are not
defined anywhere in I<Fvwm>, but exist as convenience to the module programmer.

=over 8

=item P_LAZY_HANDLERS

If this option is set, then any new handlers created are set automatically to
ignore return codes when evaluated in the loop that B<processPacket>
executes. Since the idea is to use return values to detect errors, setting
this is of dubious usefulness. But it can have its application (though some
would say that explicitly setting the handlers in this fashion is clearer).

=item P_PACKET_PASSALL

This option tells B<processPacket> not to strip out any extra arguments
from packets such as B<M_STRING> that may have extra data after the
variable-length string. It is not set by default.

=item P_STRIP_NEWLINES

If this option is set, then those packets that pass text data (such as
B<M_ICON_NAME> or B<M_STRING>) will have any trailing new-lines stripped
(but not internal ones). This option is set by default.

=item P_ALL_OPTIONS

A combination of all B<P_*> value, useful as a mask for a logical and.

=back

=head1 EXAMPLES

Examples are provided in the B<scripts> directory of the distribution.
These are:

=over 8

=item PerlWinList

A simple window-listing program that demonstrates simple module/Fvwm
communication, without a lot of features to clutter up the source code.
Outputs to C</dev/console>.

=back

=head1 BUGS

Would not surprise me in the least.

=head1 CAVEATS

In keeping with the UNIX philosophy, B<X11::Fvwm> does not keep you from
doing stupid things, as that would also keep you from doing clever things.
What this means is that there are several areas with which you can hang your
module or even royally confuse your running I<Fvwm> process. This is due to
flexibility, not bugs.

The B<ColorLimit> parameter that is fetched by getConfigInfo is only
accessible if you have applied the color-limiting patch to Fvwm 2.0.45.
The fate of that patch (and others) in future releases of Fvwm remains to
be seen.

The contents of the B<M_WINDOWSHADE> and B<M_DEWINDOWSHADE> packets is
based on a patch submitted by the author. Without this patch, these packets
only return one integer value, the X window ID of the window in question.
Access to the frame ID or the database ID is dependant on this patch.

=head1 AUTHOR

Randy J. Ray <randy@byz.org>

=head1 ADDITIONAL CREDITS

Considerable text used in defining the packet types was taken from or based
heavily upon the F<modules.tex> file written by Robert J. Nation, which is
distributed with I<Fvwm>.

=head1 SEE ALSO

For more information, see L<fvwm> and L<X11::Fvwm::Tk>

=cut
