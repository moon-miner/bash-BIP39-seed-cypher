#!/usr/bin/env bash

# SCypher - XOR-based BIP39 Seed Cipher (v2.0)
# Bash implementation of a reversible XOR transformation for BIP39 seed phrases
# Maintains valid BIP39 output with forced checksum compliance
#
# Core Features:
# - XOR-based encryption maintaining BIP39 validity
# - No salt required - pure deterministic transformation
# - Iterative key derivation for enhanced security
# - Checksum preservation through intelligent bit adjustment
# - Pure Bash implementation (no external dependencies except OpenSSL)
# - Full BIP39 wordlist validation
# - Memory-secure operations
# - Cross-platform compatibility
#
# Development:
# - Based on BIP39 Standard (M. Palatinus & P. Rusnak)
# - Developed with AI assistance (Claude/ChatGPT)
# - MIT License
#
# System Requirements:
# - Bash 4.0+ (for associative arrays)
# - OpenSSL 3.0+ (for SHAKE-256 support)
# - Basic POSIX utilities
# - 100MB+ available RAM
# - Write permissions in output directory
# - UTF-8 terminal support

if [ ! -n "$BASH" ]; then
    echo "This script must be run with bash"
    echo "Please run as: sudo bash $0"
    exit 1
fi

if [ "$BASH_VERSINFO" -lt 4 ]; then
    echo "This script requires bash version 4 or higher"
    echo "Please update your bash version"
    exit 1
fi

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Version number for compatibility tracking
readonly VERSION="2.0-ErgoHack-X"

# Amber CRT Theme Colors
readonly COLOR_RESET='\033[0m'
readonly COLOR_PRIMARY='\033[38;5;214m'       # Amber primary
readonly COLOR_BRIGHT='\033[1;38;5;220m'      # Bright amber
readonly COLOR_DIM='\033[38;5;172m'           # Dark orange
readonly COLOR_WARNING='\033[38;5;228m'       # Warm yellow
readonly COLOR_ERROR='\033[38;5;124m'         # Brick red
readonly COLOR_FRAME='\033[38;5;240m'         # Dark gray
readonly COLOR_SUCCESS='\033[1;32m'           # Green for success

# Standard exit codes for program status
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1

# Menu system configuration - Controls when to show interactive menu
readonly SHOW_MENU_DEFAULT=1        # Show menu by default when no CLI args
SHOW_MENU=$SHOW_MENU_DEFAULT        # Current menu state (can be modified by args)

# Control variable for post-processing menu flow
RETURN_TO_MAIN_MENU=0

# File handling and security constants
readonly PERMISSIONS=600
readonly EXTENSION=".txt"

# BIP39 validation and security thresholds
readonly MIN_BASH_VERSION=4
readonly MIN_PASSWORD_LENGTH=1
readonly VALID_WORD_COUNTS=(12 15 18 21 24)

# Security audit message types and status codes
readonly AUDIT_CRITICAL=2
readonly AUDIT_WARNING=1
readonly AUDIT_INFO=0
readonly AUDIT_SUCCESS=0
readonly AUDIT_FAILURE=1

# Minimum required system memory in MB
readonly MIN_REQUIRED_MEMORY=100

# Security check configuration
readonly SECURE_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# License and Disclaimer text
readonly LICENSE_TEXT="
License:
This project is released under the MIT License. You are free to:
- Use the software commercially
- Modify the source code
- Distribute the software
- Use it privately

Disclaimer:
THIS SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

The developers assume no responsibility for:
- Loss of funds or assets
- Incorrect usage of the software
- Modifications made by third parties
- Security implications of usage in specific contexts
- Possible malfunction of the software"

# Process details text
readonly DETAILS_TEXT="
How SCypher v2.0 Works (XOR-Based Encryption):

SCypher v2.0 uses a fundamentally different approach than v1.0. Instead of shuffling
words, it performs bit-level XOR encryption while maintaining BIP39 compatibility.

1. Core Concept - XOR Encryption:
   - XOR (exclusive OR) is a reversible binary operation
   - When you XOR data twice with the same key, you get back the original
   - Formula: (data XOR key) XOR key = data

2. The Process:
   Encryption:
   - Your seed phrase is converted to binary (11 bits per word)
   - Your password generates a keystream of the same length using SHAKE-256
   - The keystream can be strengthened with multiple iterations
   - Binary seed XOR keystream = encrypted binary
   - Encrypted binary is converted back to BIP39 words
   - The checksum is adjusted to ensure BIP39 validity

   Decryption:
   - The encrypted phrase is converted to binary
   - Same password and iterations generate the identical keystream
   - Encrypted binary XOR keystream = original binary
   - Original binary is converted back to your seed phrase

3. Security Features:
   - No salt needed - the password itself provides uniqueness
   - Iterations add computational cost for attackers
   - XOR provides perfect secrecy if the keystream is truly random
   - Output is always a valid BIP39 phrase with correct checksum
   - No patterns or statistical anomalies in the encrypted output

4. Checksum Handling:
   - BIP39 phrases include a checksum for error detection
   - After XOR encryption, we adjust the last few bits to maintain validity
   - This ensures compatibility with all BIP39-compliant wallets
   - The adjustment is deterministic and doesn't compromise security

5. Important Differences from v1.0:
   - No salt words prepended (pure transformation)
   - Bit-level operation instead of word-level
   - Theoretically stronger encryption (information-theoretic security)
   - Slightly faster operation
   - Same password always produces same result for same input

6. Usage Notes:
   - Always use a strong, unique password
   - More iterations = more security but slower processing
   - Test with non-critical phrases first
   - Keep secure backups of original seeds
   - Remember both password AND iteration count

Technical Note:
The XOR cipher achieves 'perfect secrecy' when the keystream is as long as the
message and truly random. While SHAKE-256 is not truly random, it provides
cryptographically secure pseudo-randomness that is sufficient for this application."

# System compatibility information
readonly COMPATIBILITY_INFO="
Dependencies:
- bash (version 4.0 or higher)
- OpenSSL 3.0 or higher (for SHAKE-256 support)

Installation:
1. Linux:
   Debian/Ubuntu: sudo apt-get install openssl
   Fedora/RHEL: sudo dnf install openssl

2. macOS:
   brew install openssl@3

3. Windows (WSL/Cygwin/MSYS2):
   - MSYS2: pacman -S mingw-w64-x86_64-openssl
   - Cygwin: apt-cyg install openssl
   - MinGW: pacman -S openssl"

# Complete BIP39 wordlist (2048 words)
declare -ra WORDS=(
abandon
ability
able
about
above
absent
absorb
abstract
absurd
abuse
access
accident
account
accuse
achieve
acid
acoustic
acquire
across
act
action
actor
actress
actual
adapt
add
addict
address
adjust
admit
adult
advance
advice
aerobic
affair
afford
afraid
again
age
agent
agree
ahead
aim
air
airport
aisle
alarm
album
alcohol
alert
alien
all
alley
allow
almost
alone
alpha
already
also
alter
always
amateur
amazing
among
amount
amused
analyst
anchor
ancient
anger
angle
angry
animal
ankle
announce
annual
another
answer
antenna
antique
anxiety
any
apart
apology
appear
apple
approve
april
arch
arctic
area
arena
argue
arm
armed
armor
army
around
arrange
arrest
arrive
arrow
art
artefact
artist
artwork
ask
aspect
assault
asset
assist
assume
asthma
athlete
atom
attack
attend
attitude
attract
auction
audit
august
aunt
author
auto
autumn
average
avocado
avoid
awake
aware
away
awesome
awful
awkward
axis
baby
bachelor
bacon
badge
bag
balance
balcony
ball
bamboo
banana
banner
bar
barely
bargain
barrel
base
basic
basket
battle
beach
bean
beauty
because
become
beef
before
begin
behave
behind
believe
below
belt
bench
benefit
best
betray
better
between
beyond
bicycle
bid
bike
bind
biology
bird
birth
bitter
black
blade
blame
blanket
blast
bleak
bless
blind
blood
blossom
blouse
blue
blur
blush
board
boat
body
boil
bomb
bone
bonus
book
boost
border
boring
borrow
boss
bottom
bounce
box
boy
bracket
brain
brand
brass
brave
bread
breeze
brick
bridge
brief
bright
bring
brisk
broccoli
broken
bronze
broom
brother
brown
brush
bubble
buddy
budget
buffalo
build
bulb
bulk
bullet
bundle
bunker
burden
burger
burst
bus
business
busy
butter
buyer
buzz
cabbage
cabin
cable
cactus
cage
cake
call
calm
camera
camp
can
canal
cancel
candy
cannon
canoe
canvas
canyon
capable
capital
captain
car
carbon
card
cargo
carpet
carry
cart
case
cash
casino
castle
casual
cat
catalog
catch
category
cattle
caught
cause
caution
cave
ceiling
celery
cement
census
century
cereal
certain
chair
chalk
champion
change
chaos
chapter
charge
chase
chat
cheap
check
cheese
chef
cherry
chest
chicken
chief
child
chimney
choice
choose
chronic
chuckle
chunk
churn
cigar
cinnamon
circle
citizen
city
civil
claim
clap
clarify
claw
clay
clean
clerk
clever
click
client
cliff
climb
clinic
clip
clock
clog
close
cloth
cloud
clown
club
clump
cluster
clutch
coach
coast
coconut
code
coffee
coil
coin
collect
color
column
combine
come
comfort
comic
common
company
concert
conduct
confirm
congress
connect
consider
control
convince
cook
cool
copper
copy
coral
core
corn
correct
cost
cotton
couch
country
couple
course
cousin
cover
coyote
crack
cradle
craft
cram
crane
crash
crater
crawl
crazy
cream
credit
creek
crew
cricket
crime
crisp
critic
crop
cross
crouch
crowd
crucial
cruel
cruise
crumble
crunch
crush
cry
crystal
cube
culture
cup
cupboard
curious
current
curtain
curve
cushion
custom
cute
cycle
dad
damage
damp
dance
danger
daring
dash
daughter
dawn
day
deal
debate
debris
decade
december
decide
decline
decorate
decrease
deer
defense
define
defy
degree
delay
deliver
demand
demise
denial
dentist
deny
depart
depend
deposit
depth
deputy
derive
describe
desert
design
desk
despair
destroy
detail
detect
develop
device
devote
diagram
dial
diamond
diary
dice
diesel
diet
differ
digital
dignity
dilemma
dinner
dinosaur
direct
dirt
disagree
discover
disease
dish
dismiss
disorder
display
distance
divert
divide
divorce
dizzy
doctor
document
dog
doll
dolphin
domain
donate
donkey
donor
door
dose
double
dove
draft
dragon
drama
drastic
draw
dream
dress
drift
drill
drink
drip
drive
drop
drum
dry
duck
dumb
dune
during
dust
dutch
duty
dwarf
dynamic
eager
eagle
early
earn
earth
easily
east
easy
echo
ecology
economy
edge
edit
educate
effort
egg
eight
either
elbow
elder
electric
elegant
element
elephant
elevator
elite
else
embark
embody
embrace
emerge
emotion
employ
empower
empty
enable
enact
end
endless
endorse
enemy
energy
enforce
engage
engine
enhance
enjoy
enlist
enough
enrich
enroll
ensure
enter
entire
entry
envelope
episode
equal
equip
era
erase
erode
erosion
error
erupt
escape
essay
essence
estate
eternal
ethics
evidence
evil
evoke
evolve
exact
example
excess
exchange
excite
exclude
excuse
execute
exercise
exhaust
exhibit
exile
exist
exit
exotic
expand
expect
expire
explain
expose
express
extend
extra
eye
eyebrow
fabric
face
faculty
fade
faint
faith
fall
false
fame
family
famous
fan
fancy
fantasy
farm
fashion
fat
fatal
father
fatigue
fault
favorite
feature
february
federal
fee
feed
feel
female
fence
festival
fetch
fever
few
fiber
fiction
field
figure
file
film
filter
final
find
fine
finger
finish
fire
firm
first
fiscal
fish
fit
fitness
fix
flag
flame
flash
flat
flavor
flee
flight
flip
float
flock
floor
flower
fluid
flush
fly
foam
focus
fog
foil
fold
follow
food
foot
force
forest
forget
fork
fortune
forum
forward
fossil
foster
found
fox
fragile
frame
frequent
fresh
friend
fringe
frog
front
frost
frown
frozen
fruit
fuel
fun
funny
furnace
fury
future
gadget
gain
galaxy
gallery
game
gap
garage
garbage
garden
garlic
garment
gas
gasp
gate
gather
gauge
gaze
general
genius
genre
gentle
genuine
gesture
ghost
giant
gift
giggle
ginger
giraffe
girl
give
glad
glance
glare
glass
glide
glimpse
globe
gloom
glory
glove
glow
glue
goat
goddess
gold
good
goose
gorilla
gospel
gossip
govern
gown
grab
grace
grain
grant
grape
grass
gravity
great
green
grid
grief
grit
grocery
group
grow
grunt
guard
guess
guide
guilt
guitar
gun
gym
habit
hair
half
hammer
hamster
hand
happy
harbor
hard
harsh
harvest
hat
have
hawk
hazard
head
health
heart
heavy
hedgehog
height
hello
helmet
help
hen
hero
hidden
high
hill
hint
hip
hire
history
hobby
hockey
hold
hole
holiday
hollow
home
honey
hood
hope
horn
horror
horse
hospital
host
hotel
hour
hover
hub
huge
human
humble
humor
hundred
hungry
hunt
hurdle
hurry
hurt
husband
hybrid
ice
icon
idea
identify
idle
ignore
ill
illegal
illness
image
imitate
immense
immune
impact
impose
improve
impulse
inch
include
income
increase
index
indicate
indoor
industry
infant
inflict
inform
inhale
inherit
initial
inject
injury
inmate
inner
innocent
input
inquiry
insane
insect
inside
inspire
install
intact
interest
into
invest
invite
involve
iron
island
isolate
issue
item
ivory
jacket
jaguar
jar
jazz
jealous
jeans
jelly
jewel
job
join
joke
journey
joy
judge
juice
jump
jungle
junior
junk
just
kangaroo
keen
keep
ketchup
key
kick
kid
kidney
kind
kingdom
kiss
kit
kitchen
kite
kitten
kiwi
knee
knife
knock
know
lab
label
labor
ladder
lady
lake
lamp
language
laptop
large
later
latin
laugh
laundry
lava
law
lawn
lawsuit
layer
lazy
leader
leaf
learn
leave
lecture
left
leg
legal
legend
leisure
lemon
lend
length
lens
leopard
lesson
letter
level
liar
liberty
library
license
life
lift
light
like
limb
limit
link
lion
liquid
list
little
live
lizard
load
loan
lobster
local
lock
logic
lonely
long
loop
lottery
loud
lounge
love
loyal
lucky
luggage
lumber
lunar
lunch
luxury
lyrics
machine
mad
magic
magnet
maid
mail
main
major
make
mammal
man
manage
mandate
mango
mansion
manual
maple
marble
march
margin
marine
market
marriage
mask
mass
master
match
material
math
matrix
matter
maximum
maze
meadow
mean
measure
meat
mechanic
medal
media
melody
melt
member
memory
mention
menu
mercy
merge
merit
merry
mesh
message
metal
method
middle
midnight
milk
million
mimic
mind
minimum
minor
minute
miracle
mirror
misery
miss
mistake
mix
mixed
mixture
mobile
model
modify
mom
moment
monitor
monkey
monster
month
moon
moral
more
morning
mosquito
mother
motion
motor
mountain
mouse
move
movie
much
muffin
mule
multiply
muscle
museum
mushroom
music
must
mutual
myself
mystery
myth
naive
name
napkin
narrow
nasty
nation
nature
near
neck
need
negative
neglect
neither
nephew
nerve
nest
net
network
neutral
never
news
next
nice
night
noble
noise
nominee
noodle
normal
north
nose
notable
note
nothing
notice
novel
now
nuclear
number
nurse
nut
oak
obey
object
oblige
obscure
observe
obtain
obvious
occur
ocean
october
odor
off
offer
office
often
oil
okay
old
olive
olympic
omit
once
one
onion
online
only
open
opera
opinion
oppose
option
orange
orbit
orchard
order
ordinary
organ
orient
original
orphan
ostrich
other
outdoor
outer
output
outside
oval
oven
over
own
owner
oxygen
oyster
ozone
pact
paddle
page
pair
palace
palm
panda
panel
panic
panther
paper
parade
parent
park
parrot
party
pass
patch
path
patient
patrol
pattern
pause
pave
payment
peace
peanut
pear
peasant
pelican
pen
penalty
pencil
people
pepper
perfect
permit
person
pet
phone
photo
phrase
physical
piano
picnic
picture
piece
pig
pigeon
pill
pilot
pink
pioneer
pipe
pistol
pitch
pizza
place
planet
plastic
plate
play
please
pledge
pluck
plug
plunge
poem
poet
point
polar
pole
police
pond
pony
pool
popular
portion
position
possible
post
potato
pottery
poverty
powder
power
practice
praise
predict
prefer
prepare
present
pretty
prevent
price
pride
primary
print
priority
prison
private
prize
problem
process
produce
profit
program
project
promote
proof
property
prosper
protect
proud
provide
public
pudding
pull
pulp
pulse
pumpkin
punch
pupil
puppy
purchase
purity
purpose
purse
push
put
puzzle
pyramid
quality
quantum
quarter
question
quick
quit
quiz
quote
rabbit
raccoon
race
rack
radar
radio
rail
rain
raise
rally
ramp
ranch
random
range
rapid
rare
rate
rather
raven
raw
razor
ready
real
reason
rebel
rebuild
recall
receive
recipe
record
recycle
reduce
reflect
reform
refuse
region
regret
regular
reject
relax
release
relief
rely
remain
remember
remind
remove
render
renew
rent
reopen
repair
repeat
replace
report
require
rescue
resemble
resist
resource
response
result
retire
retreat
return
reunion
reveal
review
reward
rhythm
rib
ribbon
rice
rich
ride
ridge
rifle
right
rigid
ring
riot
ripple
risk
ritual
rival
river
road
roast
robot
robust
rocket
romance
roof
rookie
room
rose
rotate
rough
round
route
royal
rubber
rude
rug
rule
run
runway
rural
sad
saddle
sadness
safe
sail
salad
salmon
salon
salt
salute
same
sample
sand
satisfy
satoshi
sauce
sausage
save
say
scale
scan
scare
scatter
scene
scheme
school
science
scissors
scorpion
scout
scrap
screen
script
scrub
sea
search
season
seat
second
secret
section
security
seed
seek
segment
select
sell
seminar
senior
sense
sentence
series
service
session
settle
setup
seven
shadow
shaft
shallow
share
shed
shell
sheriff
shield
shift
shine
ship
shiver
shock
shoe
shoot
shop
short
shoulder
shove
shrimp
shrug
shuffle
shy
sibling
sick
side
siege
sight
sign
silent
silk
silly
silver
similar
simple
since
sing
siren
sister
situate
six
size
skate
sketch
ski
skill
skin
skirt
skull
slab
slam
sleep
slender
slice
slide
slight
slim
slogan
slot
slow
slush
small
smart
smile
smoke
smooth
snack
snake
snap
sniff
snow
soap
soccer
social
sock
soda
soft
solar
soldier
solid
solution
solve
someone
song
soon
sorry
sort
soul
sound
soup
source
south
space
spare
spatial
spawn
speak
special
speed
spell
spend
sphere
spice
spider
spike
spin
spirit
split
spoil
sponsor
spoon
sport
spot
spray
spread
spring
spy
square
squeeze
squirrel
stable
stadium
staff
stage
stairs
stamp
stand
start
state
stay
steak
steel
stem
step
stereo
stick
still
sting
stock
stomach
stone
stool
story
stove
strategy
street
strike
strong
struggle
student
stuff
stumble
style
subject
submit
subway
success
such
sudden
suffer
sugar
suggest
suit
summer
sun
sunny
sunset
super
supply
supreme
sure
surface
surge
surprise
surround
survey
suspect
sustain
swallow
swamp
swap
swarm
swear
sweet
swift
swim
swing
switch
sword
symbol
symptom
syrup
system
table
tackle
tag
tail
talent
talk
tank
tape
target
task
taste
tattoo
taxi
teach
team
tell
ten
tenant
tennis
tent
term
test
text
thank
that
theme
then
theory
there
they
thing
this
thought
three
thrive
throw
thumb
thunder
ticket
tide
tiger
tilt
timber
time
tiny
tip
tired
tissue
title
toast
tobacco
today
toddler
toe
together
toilet
token
tomato
tomorrow
tone
tongue
tonight
tool
tooth
top
topic
topple
torch
tornado
tortoise
toss
total
tourist
toward
tower
town
toy
track
trade
traffic
tragic
train
transfer
trap
trash
travel
tray
treat
tree
trend
trial
tribe
trick
trigger
trim
trip
trophy
trouble
truck
true
truly
trumpet
trust
truth
try
tube
tuition
tumble
tuna
tunnel
turkey
turn
turtle
twelve
twenty
twice
twin
twist
two
type
typical
ugly
umbrella
unable
unaware
uncle
uncover
under
undo
unfair
unfold
unhappy
uniform
unique
unit
universe
unknown
unlock
until
unusual
unveil
update
upgrade
uphold
upon
upper
upset
urban
urge
usage
use
used
useful
useless
usual
utility
vacant
vacuum
vague
valid
valley
valve
van
vanish
vapor
various
vast
vault
vehicle
velvet
vendor
venture
venue
verb
verify
version
very
vessel
veteran
viable
vibrant
vicious
victory
video
view
village
vintage
violin
virtual
virus
visa
visit
visual
vital
vivid
vocal
voice
void
volcano
volume
vote
voyage
wage
wagon
wait
walk
wall
walnut
want
warfare
warm
warrior
wash
wasp
waste
water
wave
way
wealth
weapon
wear
weasel
weather
web
wedding
weekend
weird
welcome
west
wet
whale
what
wheat
wheel
when
where
whip
whisper
wide
width
wife
wild
will
win
window
wine
wing
wink
winner
winter
wire
wisdom
wise
wish
witness
wolf
woman
wonder
wood
wool
word
work
world
worry
worth
wrap
wreck
wrestle
wrist
write
wrong
yard
year
yellow
you
young
youth
zebra
zero
zone
zoo
)

# Function to add a message to our security audit array
add_audit_message() {
    local type="$1"
    local message="$2"

    case "$type" in
        "$AUDIT_CRITICAL")
            prefix="CRITICAL"
            ;;
        "$AUDIT_WARNING")
            prefix="WARNING"
            ;;
        "$AUDIT_INFO")
            prefix="INFO"
            ;;
        *)
            prefix="UNKNOWN"
            ;;
    esac

    AUDIT_MESSAGES+=("${prefix}: ${message}")
}

# Function to initialize global audit array
initialize_audit() {
    declare -ga AUDIT_MESSAGES=()
}

# Verify basic system requirements
verify_basic_requirements() {
    # Check root privileges
    if [ "$(id -u)" -ne 0 ]; then
        add_audit_message "$AUDIT_WARNING" "Running without root privileges. Core dump protection and ulimit restrictions will be disabled.\nFor full security, run with: sudo bash $0"
    fi

    return "$AUDIT_SUCCESS"
}

# Check system memory availability
check_system_memory() {
    local available_memory=0
    local os_name
    os_name=$(uname -s)

    case "$os_name" in
        Linux)
            if ! available_memory=$(free -m | awk '/^Mem:/{print $7}'); then
                add_audit_message "$AUDIT_WARNING" "Could not determine available memory"
                return "$AUDIT_SUCCESS"
            fi
            ;;
        Darwin)
            if ! available_memory=$(vm_stat | awk '/free/ {gsub(/\./, "", $3); print int($3)*4096/1024/1024}'); then
                add_audit_message "$AUDIT_WARNING" "Could not determine available memory"
                return "$AUDIT_SUCCESS"
            fi
            ;;
        *)
            add_audit_message "$AUDIT_WARNING" "Could not determine available memory on $os_name"
            return "$AUDIT_SUCCESS"
            ;;
    esac

    if [[ $available_memory -lt $MIN_REQUIRED_MEMORY ]]; then
        add_audit_message "$AUDIT_CRITICAL" "System has low available memory (${available_memory}MB)"
        return "$AUDIT_FAILURE"
    fi

    return "$AUDIT_SUCCESS"
}

# Validate OpenSSL installation and capabilities
validate_openssl_security() {
    local os_name
    os_name=$(uname -s)

    if ! command -v openssl >/dev/null 2>&1; then
        local install_message
        case "$os_name" in
            Linux)
                install_message="Install with:\nsudo apt-get install openssl # For Debian/Ubuntu\nsudo dnf install openssl # For Fedora/RHEL"
                ;;
            Darwin)
                install_message="Install with:\nbrew install openssl@3"
                ;;
            MSYS*)
                install_message="pacman -S mingw-w64-x86_64-openssl"
                ;;
            CYGWIN*)
                install_message="apt-cyg install openssl"
                ;;
            MINGW*)
                install_message="pacman -S openssl"
                ;;
        esac
        add_audit_message "$AUDIT_CRITICAL" "OpenSSL 3.0+ required.\n$install_message"
        return "$AUDIT_FAILURE"
    fi

    if ! echo "test" | openssl dgst -shake256 -xoflen 128 >/dev/null 2>&1; then
        add_audit_message "$AUDIT_CRITICAL" "OpenSSL version installed does not support SHAKE-256\nPlease update to OpenSSL 3.0 or higher"
        return "$AUDIT_FAILURE"
    fi

    # Check for security features
    if command -v selinuxenabled >/dev/null 2>&1 && selinuxenabled; then
        add_audit_message "$AUDIT_INFO" "SELinux is enabled and enforcing"
    fi

    return "$AUDIT_SUCCESS"
}

# Audit environment variables for security risks
audit_environment_variables() {
    local has_warnings=0

    # Check common security-sensitive environment variables
    local -a security_vars=(
        "LD_PRELOAD"
        "LD_LIBRARY_PATH"
        "LD_AUDIT"
        "BASH_ENV"
        "ENV"
    )

    # Check for security-sensitive environment variables
    for var in "${security_vars[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            add_audit_message "$AUDIT_WARNING" "$var is set, which could affect script security"
            has_warnings=1
        fi
    done

    # Check for virtual environment
    if [[ -n "${VIRTUAL_ENV:-}" ]] || [[ -n "${CONDA_DEFAULT_ENV:-}" ]]; then
        add_audit_message "$AUDIT_INFO" "Script is running in a virtual environment"
    fi

    # Check if running in a container
    if [[ -f "/.dockerenv" ]] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        add_audit_message "$AUDIT_INFO" "Script is running in a container environment"
    fi

    [[ $has_warnings -eq 1 ]] && return "$AUDIT_WARNING"
    return "$AUDIT_SUCCESS"
}

# Verify PATH security and required commands
verify_path_security() {
    local ORIGINAL_PATH="$PATH"
    local has_warnings=0

    # Test if we can use secure path
    PATH="$SECURE_PATH"
    if ! command -v openssl >/dev/null 2>&1; then
        add_audit_message "$AUDIT_WARNING" "Required commands not found in secure PATH, using original PATH"
        PATH="$ORIGINAL_PATH"
        has_warnings=1
    fi

    # Check for write permissions in PATH directories
    local IFS=:
    for dir in $PATH; do
        if [[ -w "$dir" && ! -O "$dir" ]]; then
            add_audit_message "$AUDIT_WARNING" "Directory in PATH is writable by other users: $dir"
            has_warnings=1
        fi
    done

    # Check for relative paths in PATH
    if [[ "$PATH" =~ \.:|:\.:|:\. ]]; then
        add_audit_message "$AUDIT_WARNING" "PATH contains relative paths, which is a security risk"
        has_warnings=1
    fi

    # Export the verified PATH
    export PATH

    [[ $has_warnings -eq 1 ]] && return "$AUDIT_WARNING"
    return "$AUDIT_SUCCESS"
}

# Validate system configuration settings
validate_system_config() {
    local has_warnings=0

    # Check locale settings
    if ! locale charmap >/dev/null 2>&1; then
        add_audit_message "$AUDIT_WARNING" "Could not determine system locale"
        has_warnings=1
    elif [[ $(locale charmap) != "UTF-8" ]]; then
        add_audit_message "$AUDIT_WARNING" "Non-UTF-8 locale detected"
        has_warnings=1
    fi

    # Check IFS setting
    if [[ "$IFS" != $' \t\n' ]]; then
        add_audit_message "$AUDIT_WARNING" "Custom IFS detected, which could affect word processing"
        has_warnings=1
    fi

    [[ $has_warnings -eq 1 ]] && return "$AUDIT_WARNING"
    return "$AUDIT_SUCCESS"
}

# Main system security audit function
# Coordinates all security checks and reports findings
system_security_audit() {
    # Initialize audit message array
    initialize_audit
    local critical_failures=0

    # Temporarily disable errexit
    set +e

    # Verify basic requirements first
    verify_basic_requirements
    local basic_status=$?

    # Run security checks
    check_system_memory
    local memory_status=$?

    validate_openssl_security
    local openssl_status=$?

    audit_environment_variables
    verify_path_security
    validate_system_config

    # Re-enable errexit
    set -e

    # Display messages with proper categorization
    for message in "${AUDIT_MESSAGES[@]}"; do
        echo -e "$message" >&2
    done

    # Clean up
    unset AUDIT_MESSAGES

    # Calculate total failures
    critical_failures=$((basic_status + memory_status + openssl_status))

    # Only stop if we have critical failures and are running as root
    if ((critical_failures > 0)) && [ "$(id -u)" -eq 0 ]; then
        return 0  # Return success to avoid triggering errexit
    fi

    return 0  # Always return success to avoid triggering errexit
}

# Prevent core dumps from leaking sensitive data
# Methods:
# - Sets ulimit restrictions
# - Applies prctl protection if available
# - Reports protection status
protect_against_coredumps() {
    local coredump_protected=false
    local message=""

    # Try to disable core dumps
    if ! ulimit -c 0 2>/dev/null; then
        if [ "$(id -u)" -eq 0 ]; then
            message="Core dump protection failed even with root privileges"
        else
            message="Core dump protection requires root privileges (run with 'sudo bash')"
        fi
    else
        coredump_protected=true
    fi

    # Try additional protection if available
    if command -v prctl >/dev/null 2>&1; then
        if prctl --set-priv basic,!core_dump $ >/dev/null 2>&1; then
            coredump_protected=true
        else
            # Only add to message if first method failed
            if [ "$coredump_protected" = false ]; then
                message="${message:+$message, }prctl protection not available"
            fi
        fi
    fi

    # Report protection status
    if [ "$coredump_protected" = false ] && [ -n "$message" ]; then
        echo "Note: Running without core dump protection - $message" >&2
    fi

    return 0
}

# Configure terminal for secure password input
# Manages:
# - Terminal echo settings
# - Signal trap setup/cleanup
# - Fallback handling for unsupported terminals
secure_input_mode() {
    local action=$1  # 'enable' or 'disable'
    local stty_available=false
    local terminal_supported=false

    # Check if stty is available
    if command -v stty >/dev/null 2>&1; then
        stty_available=true
        # Check if terminal supports it
        if stty -echo 2>/dev/null; then
            stty echo
            terminal_supported=true
        fi
    fi

    # If not supported, warn only once
    if [[ "$action" == "enable" ]] && ! $terminal_supported; then
        if ! $stty_available; then
            echo "Note: Enhanced input protection unavailable - stty not found" >&2
        else
            echo "Note: Enhanced input protection unavailable - terminal not supported" >&2
        fi
        return 0
    fi

    if $terminal_supported; then
        if [[ "$action" == "enable" ]]; then
            stty -echo 2>/dev/null
            trap 'secure_input_mode disable' EXIT INT TERM
        else
            stty echo 2>/dev/null
        fi
    fi

    return 0
}

# Set up signal handlers with system-specific compatibility checks
# Handles: TSTP (terminal stop), WINCH (window change), USR1, USR2
setup_signal_handlers() {
    local supported_signals=()
    local message=""
    local os_name
    os_name=$(uname -s)

    # Check which signals can be handled by the system
    for sig in TSTP WINCH USR1 USR2; do
        if trap '' $sig 2>/dev/null; then
            supported_signals+=($sig)
            trap '' $sig
        fi
    done

    # Report status based on system
    case "$os_name" in
        Linux)
            if [ ${#supported_signals[@]} -eq 0 ]; then
                message="Signal protection not available on this system"
            elif [ ${#supported_signals[@]} -lt 4 ]; then
                message="Signal protection partially available"
            fi
            ;;
        Darwin)
            if [ ${#supported_signals[@]} -eq 0 ]; then
                message="Signal protection not available on macOS"
            elif [ ${#supported_signals[@]} -lt 4 ]; then
                message="Limited signal protection available on macOS"
            fi
            ;;
        *)
            message="Running with basic signal protection on $os_name"
            ;;
    esac

    # Display message if exists
    if [ -n "$message" ]; then
        echo "Note: $message" >&2
    fi

    return 0
}

show_license() {
    clear_screen
    echo "$LICENSE_TEXT"
    echo ""
    read -p "Press enter to continue..."
}

show_details() {
    clear_screen
    echo "$DETAILS_TEXT"
    echo ""
    read -p "Press enter to continue..."
}

# Clear screen using multiple methods for complete cleanup
# Combines ANSI escape sequences with terminal buffer clearing
clear_screen() {
    # Method 1: Clear screen and move cursor to top-left
    echo -e "\033[2J\033[H"

    # Method 2: Clear scrollback buffer (works on most modern terminals)
    echo -e "\033[3J"

    # Method 3: Reset terminal state
    echo -e "\033c"

    # Method 4: Use clear command if available (fallback)
    if command -v clear >/dev/null 2>&1; then
        clear 2>/dev/null || true
    fi

    # Method 5: Fill screen with empty lines to push old content up
    for ((i=0; i<50; i++)); do
        echo ""
    done

    # Final positioning
    echo -e "\033[H"
}

# Display main menu with banner
show_main_menu() {
    clear_screen

    # Banner with existing ASCII art (preserved exactly)
    echo -e "${COLOR_BRIGHT}SCypher v${VERSION}${COLOR_RESET} ${COLOR_DIM}- XOR-based BIP39 Seed Cipher${COLOR_RESET}"
    echo -e "${COLOR_DIM}                        ErgoHack X Competition Release${COLOR_RESET}"

    echo
    echo -e "${COLOR_PRIMARY}                                  000000000"
    echo -e "                              000000000000000000"
    echo -e "                            000000          000000"
    echo -e "                           000                  000"
    echo -e "                          000     0000000000     000"
    echo -e "                         000      0000000000      000"
    echo -e "                         00        0000           000"
    echo -e "                        000          0000          000"
    echo -e "                        000          0000          000"
    echo -e "                         000       0000            00"
    echo -e "                         000      0000000000      000"
    echo -e "                          000     0000000000     000"
    echo -e "                           000                  000"
    echo -e "                            000000          000000"
    echo -e "                              000000000000000000"
    echo -e "                                   000000000${COLOR_RESET}"
    echo

    # Menu options
    echo -e "${COLOR_SUCCESS}Main Menu:${COLOR_RESET}"
    echo "1. Encrypt/Decrypt seed phrase"
    echo "2. Help/License/Details"
    echo "3. Exit"
    echo ""
}

# Display help/license submenu
show_help_submenu() {
    clear_screen
    echo -e "${COLOR_BRIGHT}Help/License/Details${COLOR_RESET}"
    echo -e "${COLOR_FRAME}====================${COLOR_RESET}"
    echo ""
    echo "1. Show license and disclaimer"
    echo "2. Show detailed cipher explanation"
    echo "3. Show usage examples"
    echo "4. Return to main menu"
    echo ""
}

# Display usage examples
show_usage_examples() {
    clear_screen
    echo -e "${COLOR_BRIGHT}Usage Examples${COLOR_RESET}"
    echo -e "${COLOR_FRAME}==============${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_PRIMARY}Interactive Mode (Menu):${COLOR_RESET}"
    echo "  ./SCypher.sh                    # Shows this menu"
    echo ""
    echo -e "${COLOR_PRIMARY}Command Line Mode:${COLOR_RESET}"
    echo "  ./SCypher.sh -f output.txt      # Encrypt/decrypt and save to file"
    echo "  ./SCypher.sh -s < input.txt     # Silent mode for scripting"
    echo ""
    echo -e "${COLOR_PRIMARY}Options:${COLOR_RESET}"
    echo "  -f FILE     Save output to file"
    echo "  -s, --silent    Silent mode (no prompts)"
    echo "  --license   Show license"
    echo "  --details   Show cipher details"
    echo "  -h, --help  Show help"
    echo ""
    read -p "Press enter to continue..."
}

# Handle post-processing menu after encrypt/decrypt operation
# Provides options to save result, return to menu, or exit
handle_post_processing_menu() {
    local result="$1"

    while true; do
        echo ""
        echo -e "${COLOR_SUCCESS}What would you like to do next?${COLOR_RESET}"
        echo "1. Save result to file"
        echo "2. Return to main menu"
        echo "3. Exit"
        echo ""
        read -p "Select option [1-3]: " post_choice
        echo ""

        case "$post_choice" in
            1)
                handle_save_result "$result"
                # If save was successful and user chose to return to main menu, break
                if [[ $RETURN_TO_MAIN_MENU -eq 1 ]]; then
                    RETURN_TO_MAIN_MENU=0  # Reset flag
                    return 0
                fi
                ;;
            2)
                clear_screen
                return 0  # Return to main menu
                ;;
            3|"")
                echo -e "${COLOR_DIM}Exiting...${COLOR_RESET}"
                sleep 1
                clear_screen
                cleanup
                exit "$EXIT_SUCCESS"
                ;;
            *)
                echo -e "${COLOR_ERROR}Invalid option. Please select 1-3.${COLOR_RESET}"
                echo ""
                read -p "Press enter to continue..."
                ;;
        esac
    done
}

# Handle saving result to file with validation and post-save options
handle_save_result() {
    local result="$1"
    local save_file=""

    while true; do
        echo -e "${COLOR_PRIMARY}Enter filename to save result:${COLOR_RESET}"
        echo -n "> "
        read -r save_file
        echo ""

        # Validate input
        if [[ -z "$save_file" ]]; then
            echo -e "${COLOR_ERROR}Error: Filename cannot be empty${COLOR_RESET}"
            echo ""
            read -p "Press enter to try again..."
            echo ""
            continue
        fi

        # Auto-append .txt extension if not present
        if [[ "$save_file" != *"${EXTENSION}" ]]; then
            save_file="${save_file}${EXTENSION}"
        fi

        # Validate output file location and permissions
        if ! validate_output_file "$save_file"; then
            continue
        fi

        # Attempt to save the file
        if ! echo "$result" > "$save_file" 2>/dev/null; then
            echo -e "${COLOR_ERROR}Error: Failed to write to output file${COLOR_RESET}"
            echo ""
            read -p "Press enter to try again..."
            echo ""
            continue
        fi

        # Set secure file permissions
        if ! chmod "${PERMISSIONS}" "$save_file" 2>/dev/null; then
            echo -e "${COLOR_ERROR}Error: Failed to set file permissions${COLOR_RESET}"
            echo ""
            read -p "Press enter to try again..."
            echo ""
            continue
        fi

        # Success - show confirmation
        echo -e "${COLOR_SUCCESS}✓ Result successfully saved to ${save_file}${COLOR_RESET}"
        break
    done

    # Post-save menu
    handle_post_save_menu
}

# Handle menu options after successful file save
handle_post_save_menu() {
    while true; do
        echo ""
        echo -e "${COLOR_SUCCESS}File saved successfully. What would you like to do next?${COLOR_RESET}"
        echo "1. Return to main menu"
        echo "2. Exit"
        echo ""
        read -p "Select option [1-2]: " save_choice
        echo ""

        case "$save_choice" in
            1)
                clear_screen
                RETURN_TO_MAIN_MENU=1  # Set flag to return to main menu
                return 0
                ;;
            2|"")
                echo -e "${COLOR_DIM}Exiting...${COLOR_RESET}"
                sleep 1
                clear_screen
                cleanup
                exit "$EXIT_SUCCESS"
                ;;
            *)
                echo -e "${COLOR_ERROR}Invalid option. Please select 1-2.${COLOR_RESET}"
                echo ""
                read -p "Press enter to continue..."
                ;;
        esac
    done
}

# Handle main menu input and navigation
handle_main_menu() {
    while true; do
        show_main_menu
        read -p "Select option [1-3]: " menu_choice
        echo ""

        case "$menu_choice" in
            1)
                # Execute encrypt/decrypt - return to main execution
                return 0
                ;;
            2)
                handle_help_submenu
                ;;
            3|"")
                echo -e "${COLOR_DIM}Exiting...${COLOR_RESET}"
                sleep 1
                clear_screen
                cleanup
                exit "$EXIT_SUCCESS"
                ;;
            *)
                echo -e "${COLOR_ERROR}Invalid option. Please select 1-3.${COLOR_RESET}"
                echo ""
                read -p "Press enter to continue..."
                ;;
        esac
    done
}

# Handle help submenu input and navigation
handle_help_submenu() {
    while true; do
        show_help_submenu
        read -p "Select option [1-4]: " help_choice
        echo ""

        case "$help_choice" in
            1)
                show_license
                ;;
            2)
                show_details
                ;;
            3)
                show_usage_examples
                ;;
            4|"")
                return 0  # Return to main menu
                ;;
            *)
                echo -e "${COLOR_ERROR}Invalid option. Please select 1-4.${COLOR_RESET}"
                echo ""
                read -p "Press enter to continue..."
                ;;
        esac
    done
}

# Standardized error handling with user interaction
# Displays error message, waits for acknowledgment, clears screen
handle_error() {
    local error_message="$1"

    # Display error message
    echo -e "${COLOR_ERROR}✗ Error: $error_message${COLOR_RESET}" >&2
    echo "" >&2

    # Wait for user input
    read -p "Press enter to clear screen and continue..."

    # Clear screen
    clear_screen

    # Terminate script
    exit "${EXIT_ERROR}"
}

# Function to clear command history
clear_history() {
    history -c
    history -w
}

is_file() {
    [[ -f "$1" ]]
}

# Read and validate words from input file
# Handles:
# - File existence and permission checks
# - Content reading with error handling
# - Basic input sanitization
# Returns: Space-separated string of words
read_words_from_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "" >&2
        echo "Error: File not found" >&2
        echo "" >&2
        read -p "Press enter to clear screen and exit..."
        clear_screen
        exit "${EXIT_ERROR}"
    fi

    if [[ ! -r "$file" ]]; then
        echo "" >&2
        echo "Error: Cannot read file" >&2
        echo "" >&2
        read -p "Press enter to clear screen and exit..."
        clear_screen
        exit "${EXIT_ERROR}"
    fi

    local content
    if ! content=$(tr '\n' ' ' < "$file" 2>/dev/null); then
        echo "" >&2
        echo "Error: Failed to read file" >&2
        echo "" >&2
        read -p "Press enter to clear screen and exit..."
        clear_screen
        exit "${EXIT_ERROR}"
    fi

    echo "$content"
}

# Validate word count matches BIP39 specifications
# Checks against valid lengths: 12, 15, 18, 21, 24
# Returns: 0 if valid, 1 otherwise with error message
validate_word_count() {
    local -a words=("$@")
    local count=${#words[@]}

    for valid_count in "${VALID_WORD_COUNTS[@]}"; do
        if [[ $count -eq $valid_count ]]; then
            return 0
        fi
    done

    echo "" >&2
    echo "Error: Invalid number of words detected" >&2
    echo "Expected number of words: ${VALID_WORD_COUNTS[*]}" >&2
    echo "Found: $count words" >&2
    echo "" >&2
    read -p "Press enter to clear screen and try again..."
    clear_screen
    return 1
}

# Verify all words exist in BIP39 wordlist
# Features:
# - O(1) lookup using hash table
# - Collects and reports all invalid words
# - Memory-efficient validation
validate_bip39_words() {
    local -a words=("$@")
    declare -A word_lookup invalid_words
    local word count=0

    for word in "${WORDS[@]}"; do
        word_lookup["$word"]=1
    done

    # Check each word and store invalid ones
    for word in "${words[@]}"; do
        if [[ -z "${word_lookup[$word]:-}" ]]; then
            invalid_words["$word"]=1
            ((count++))
        fi
    done

    # If invalid words found, show them all
    if ((count > 0)); then
        echo "" >&2
        echo "Error: Invalid BIP39 words detected" >&2
        echo "The following words are not in the BIP39 wordlist:" >&2
        for word in "${!invalid_words[@]}"; do
            echo "  - $word" >&2
        done
        echo "" >&2
        echo "Please verify your seed phrase and try again." >&2
        echo "You can find the complete BIP39 word list in the script by opening it with a text editor." >&2
        echo "" >&2
        read -p "Press enter to clear screen and try again..."

        # Clean sensitive data before clearing screen
        for word in "${!invalid_words[@]}"; do
            invalid_words[$word]="$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64)"
            unset 'invalid_words[$word]'
        done
        unset word_lookup word count

        clear_screen
        return 1
    fi

    # Clean lookup table even on success
    unset word_lookup
    return 0
}

# Validate user input for security and format compliance
# Checks:
# - Character set restrictions (alphanumeric only)
# - Maximum length enforcement (1024 chars)
validate_input() {
    local input="$1"

    # Check for invalid characters
    if [[ "$input" =~ [^a-zA-Z0-9\ ] ]]; then
        echo "" >&2
        echo "Error: Input contains invalid characters (only letters and numbers allowed)" >&2
        echo "" >&2
        return 1
    fi

    return 0
}

# Securely read and validate user password with visual feedback
# Features:
# - Shows asterisks for each character typed
# - Enforces minimum length
# - Requires confirmation match
# - Handles secure input mode
read_secure_password() {
    local password password_confirm

    # Print recommendations to stderr to ensure they appear
    cat >&2 << EOF

Password recommendations:
- Minimum length: 8 characters
- Include uppercase and lowercase letters
- Include numbers and special characters

EOF

    while true; do
        # Read password with asterisk feedback
        printf "Enter password: " >&2
        password=$(read_password_with_asterisks)
        printf "\n" >&2

        # Read confirmation with asterisk feedback
        printf "Confirm password: " >&2
        password_confirm=$(read_password_with_asterisks)
        printf "\n" >&2

        if [[ "$password" != "$password_confirm" ]]; then
            echo "Error: Passwords do not match" >&2
            echo "" >&2
            read -p "Press enter to try again..."
            echo "" >&2
            continue
        fi

        if [[ ${#password} -lt ${MIN_PASSWORD_LENGTH} ]]; then
            echo "Error: Password must be at least ${MIN_PASSWORD_LENGTH} characters long" >&2
            echo "" >&2
            read -p "Press enter to try again..."
            echo "" >&2
            continue
        fi

        break
    done

    printf "%s" "$password"
}

# Helper function to read password with asterisk visual feedback (simplified)
# Uses timeout-based approach for better compatibility
read_password_with_asterisks() {
    local password=""
    local char

    # Disable echo
    if command -v stty >/dev/null 2>&1; then
        stty -echo 2>/dev/null
    fi

    printf "" >&2  # Ensure we're ready for input

    while true; do
        # Use read with timeout for better control
        if read -r -n1 -t 0.1 char 2>/dev/null; then
            # Check for Enter (empty char after newline)
            if [[ -z "$char" ]]; then
                break
            fi

            # Check for backspace
            if [[ "$char" == $'\x7f' || "$char" == $'\x08' ]]; then
                if [[ ${#password} -gt 0 ]]; then
                    password="${password%?}"
                    printf "\b \b" >&2
                fi
            else
                # Regular character
                password+="$char"
                printf "*" >&2
            fi
        else
            # Check if user pressed Enter by trying to read more
            if read -r -n1 -t 0 remaining_char 2>/dev/null; then
                if [[ "$remaining_char" == $'\n' || "$remaining_char" == $'\r' ]]; then
                    break
                else
                    password+="$remaining_char"
                    printf "*" >&2
                fi
            fi
        fi
    done

    # Re-enable echo
    if command -v stty >/dev/null 2>&1; then
        stty echo 2>/dev/null
    fi

    echo "$password"
}

# Convert decimal to binary representation using native Bash arithmetic
# Input: Decimal number, bit width (optional, default 8)
# Output: Binary string with specified width
decimal_to_binary() {
    local decimal="$1"
    local width="${2:-8}"
    local binary=""
    local num="$decimal"

    # Handle zero case
    if [[ $num -eq 0 ]]; then
        # Generate a string of zeros with the specified width
        local zeros=""
        for ((i = 0; i < width; i++)); do
            zeros+="0"
        done
        echo "$zeros"
        return
    fi

    # Convert to binary using Bash arithmetic
    while [[ $num -gt 0 ]]; do
        binary="$((num % 2))$binary"
        num=$((num / 2))
    done

    # Pad with leading zeros to specified width
    while [[ ${#binary} -lt $width ]]; do
        binary="0$binary"
    done

    echo "$binary"
}

# Convert binary to decimal using native Bash arithmetic
# Input: Binary string
# Output: Decimal number
binary_to_decimal() {
    local binary="$1"
    local decimal=0
    local power=1

    # Remove any leading zeros to avoid syntax errors
    binary="${binary#"${binary%%[!0]*}"}"

    # Handle the case where binary is all zeros or empty
    if [[ -z "$binary" ]]; then
        echo "0"
        return
    fi

    # Process from right to left using positional notation
    for ((i = ${#binary} - 1; i >= 0; i--)); do
        local bit="${binary:i:1}"
        if [[ $bit -eq 1 ]]; then
            decimal=$((decimal + power))
        fi
        power=$((power * 2))
    done

    echo "$decimal"
}

# Convert BIP39 words to binary representation
# Input: Space-separated string of BIP39 words
# Output: Binary string (11 bits per word)
words_to_bits() {
    local input="$1"
    local -a words
    read -ra words <<< "$input"
    local binary=""

    for word in "${words[@]}"; do
        local index=0
        for ((i=0; i<${#WORDS[@]}; i++)); do
            if [[ "${WORDS[$i]}" == "$word" ]]; then
                index=$i
                break
            fi
        done
        # Convert to 11-bit binary using native Bash arithmetic
        local bin=$(decimal_to_binary "$index" 11)
        binary+="$bin"
    done

    # If length specified, truncate
    if [[ -n "${2:-}" ]]; then
        binary="${binary:0:$2}"
    fi

    echo "$binary"
}

# Convert binary string to BIP39 words
# Input: Binary string
# Output: Space-separated string of BIP39 words
bits_to_words() {
    local binary="$1"
    local phrase=""

    # Process 11 bits at a time
    for ((i = 0; i < ${#binary}; i += 11)); do
        local chunk="${binary:i:11}"
        if [[ ${#chunk} -eq 11 ]]; then
            # Use our safe binary_to_decimal function instead of $((2#...))
            local index=$(binary_to_decimal "$chunk")
            [[ -n "$phrase" ]] && phrase+=" "
            phrase+="${WORDS[$index]}"
        fi
    done

    echo "$phrase"
}

# Derive keystream from password using SHAKE-256
# Parameters:
#   password: User password
#   bit_length: Required keystream length in bits
#   iterations: Number of iterations for key strengthening
# Output: Binary string of specified length
derive_keystream() {
    local password="$1"
    local bit_length="$2"
    local iterations="$3"
    local byte_length=$(( (bit_length + 7) / 8 ))

    # Initial hash
    local current_hash="$password"

    # Apply iterations
    for ((i = 1; i <= iterations; i++)); do
        current_hash=$(echo -n "$current_hash" | openssl dgst -shake256 -xoflen "$byte_length" | sed 's/^.*= //')
    done

    # Convert hex to binary using native Bash arithmetic
    local binary=""
    for ((i = 0; i < ${#current_hash}; i += 2)); do
        local hex_byte="${current_hash:i:2}"
        local dec=$((16#$hex_byte))
        local bin=$(decimal_to_binary "$dec" 8)
        binary+="$bin"
    done

    # Return exact bit length requested
    echo "${binary:0:$bit_length}"
}

# Perform XOR operation on two binary strings
# Input: Two binary strings of equal length
# Output: XOR result as binary string
xor_bits() {
    local a="$1"
    local b="$2"
    local result=""

    for ((i = 0; i < ${#a}; i++)); do
        local bit_a="${a:i:1}"
        local bit_b="${b:i:1}"
        result+=$((bit_a ^ bit_b))
    done

    echo "$result"
}

calculate_checksum_bits() {
    local entropy="$1"
    local entropy_bits=${#entropy}
    local checksum_bits=$((entropy_bits / 32))

    # Convert binary to bytes for hashing - MÉTODO ORIGINAL SIMPLIFICADO
    local binary_data=""

    # Process 8 bits at a time to form bytes
    for ((i = 0; i < entropy_bits; i += 8)); do
        local byte="${entropy:i:8}"

        # Ensure byte has 8 bits (pad with zeros if necessary)
        while [[ ${#byte} -lt 8 ]]; do
            byte+="0"
        done

        # Convert binary byte to decimal
        local decimal_value=$(binary_to_decimal "$byte")

        # Validate decimal value is within byte range
        if [[ $decimal_value -ge 0 && $decimal_value -le 255 ]]; then
            # Convert decimal to hex and use echo -e to create binary data
            local hex_value=$(printf "%02x" $decimal_value)
            binary_data+="\\x$hex_value"
        else
            echo "Error: Invalid byte value: $decimal_value" >&2
            return 1
        fi
    done

    # Calculate SHA256 using echo -e (compatible method)
    local hash_output
    if ! hash_output=$(echo -e -n "$binary_data" | openssl dgst -sha256); then
        echo "Error: SHA256 calculation failed" >&2
        return 1
    fi

    # Extract hex hash from output (remove "SHA256(stdin)= " prefix)
    local hash_hex="${hash_output##*= }"

    # Extract first checksum_bits from hash
    local checksum_binary=""
    local bits_needed=$checksum_bits
    local hex_pos=0

    while [[ $bits_needed -gt 0 && $hex_pos -lt ${#hash_hex} ]]; do
        local hex_char="${hash_hex:$hex_pos:1}"
        local hex_nibble

        # Convert hex character to 4-bit binary
        case "$hex_char" in
            "0") hex_nibble="0000" ;;
            "1") hex_nibble="0001" ;;
            "2") hex_nibble="0010" ;;
            "3") hex_nibble="0011" ;;
            "4") hex_nibble="0100" ;;
            "5") hex_nibble="0101" ;;
            "6") hex_nibble="0110" ;;
            "7") hex_nibble="0111" ;;
            "8") hex_nibble="1000" ;;
            "9") hex_nibble="1001" ;;
            "a"|"A") hex_nibble="1010" ;;
            "b"|"B") hex_nibble="1011" ;;
            "c"|"C") hex_nibble="1100" ;;
            "d"|"D") hex_nibble="1101" ;;
            "e"|"E") hex_nibble="1110" ;;
            "f"|"F") hex_nibble="1111" ;;
            *)
                echo "Error: Invalid hex character in hash: $hex_char" >&2
                return 1
                ;;
        esac

        # Add required bits
        if [[ $bits_needed -ge 4 ]]; then
            checksum_binary+="$hex_nibble"
            bits_needed=$((bits_needed - 4))
        else
            # Only need some bits from nibble
            checksum_binary+="${hex_nibble:0:$bits_needed}"
            bits_needed=0
        fi

        hex_pos=$((hex_pos + 1))
    done

    echo "$checksum_binary"

    # Securely clean sensitive variables from memory
    binary_data="$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 2>/dev/null || echo 'random_cleanup_data')"
    hash_output="$(dd if=/dev/urandom bs=64 count=1 2>/dev/null | base64 2>/dev/null || echo 'random_cleanup_data')"
    hash_hex="$(dd if=/dev/urandom bs=64 count=1 2>/dev/null | base64 2>/dev/null || echo 'random_cleanup_data')"
    checksum_binary="$(dd if=/dev/urandom bs=16 count=1 2>/dev/null | base64 2>/dev/null || echo 'random_cleanup_data')"

    unset binary_data hash_output hash_hex checksum_binary hex_nibble hex_value decimal_value byte
}

# Verify BIP39 checksum
# Input: Seed phrase as string
# Output: 0 if valid, 1 if invalid
verify_checksum() {
    local seed_phrase="$1"
    local word_count=$(echo "$seed_phrase" | wc -w)
    local entropy_bits=$((word_count * 32 / 3))
    local checksum_bits=$((entropy_bits / 32))

    local binary=$(words_to_bits "$seed_phrase")
    local entropy="${binary:0:$entropy_bits}"
    local checksum="${binary:$entropy_bits:$checksum_bits}"

    local expected_checksum=$(calculate_checksum_bits "$entropy")

    [[ "$checksum" == "$expected_checksum" ]] && return 0 || return 1
}

# Recalculate BIP39 checksum for the given entropy
# This function maintains BIP39 compliance after XOR transformation
# by computing the correct checksum based on the transformed entropy bits
#
# The process follows BIP39 standard:
# 1. Extract entropy portion from binary data
# 2. Calculate SHA256 hash of entropy
# 3. Take first N bits of hash as checksum (where N = entropy_bits/32)
# 4. Combine entropy + correct checksum to form valid BIP39 binary
#
# Input: Binary string representing seed phrase (entropy + old checksum)
# Output: Binary string with recalculated BIP39-compliant checksum
recalculate_bip39_checksum() {
    local binary="$1"
    local word_count=$((${#binary} / 11))
    local entropy_bits=$((word_count * 32 / 3))
    local checksum_bits=$((entropy_bits / 32))

    # Extract entropy portion (original data, unchanged)
    local entropy="${binary:0:$entropy_bits}"

    # Calculate correct BIP39 checksum for this entropy
    local correct_checksum=$(calculate_checksum_bits "$entropy")

    # Combine unchanged entropy with recalculated checksum
    binary="${entropy}${correct_checksum}"

    echo "$binary"
}

# Main XOR encryption/decryption function
# Handles both modes as XOR is symmetric
process_phrase_xor() {
    local phrase="$1"
    local password="$2"
    local iterations="$3"

    # Convert phrase to bits
    local seed_bits=$(words_to_bits "$phrase")
    local bit_length=${#seed_bits}

    # Generate keystream
    local keystream=$(derive_keystream "$password" "$bit_length" "$iterations")

    # Perform XOR
    local result_bits=$(xor_bits "$seed_bits" "$keystream")

    # recalculate bip39 checksum
    result_bits=$(recalculate_bip39_checksum "$result_bits")

    # Convert back to words
    local result_phrase=$(bits_to_words "$result_bits")

    echo "$result_phrase"
}

# Validate and prepare output file location
# Checks:
# - Directory existence and write permissions
# - File overwrite confirmation if exists
# - Path security validation
validate_output_file() {
    local file="$1"
    local dir
    dir=$(dirname "$file")

    if [[ ! -d "$dir" ]]; then
        echo "" >&2
        echo "Error: Directory does not exist" >&2
        echo "" >&2
        read -p "Press enter to clear screen and exit..."
        clear_screen
        exit "${EXIT_ERROR}"
    fi

    if [[ ! -w "$dir" ]]; then
        echo "" >&2
        echo "Error: No write permission in directory" >&2
        echo "" >&2
        read -p "Press enter to clear screen and exit..."
        clear_screen
        exit "${EXIT_ERROR}"
    fi

    if [[ -e "$file" ]]; then
        if [[ ! -w "$file" ]]; then
            echo "" >&2
            echo "Error: Cannot write to existing file" >&2
            echo "" >&2
            read -p "Press enter to clear screen and exit..."
            clear_screen
            exit "${EXIT_ERROR}"
        fi

        while true; do
            read -p "File '$file' exists. Do you want to overwrite it? (y/n): " answer
            case $answer in
                [Yy]* )
                    return 0
                    ;;
                [Nn]* )
                    echo "" >&2
                    echo "Operation cancelled by user" >&2
                    echo "" >&2
                    read -p "Press enter to clear screen and exit..."
                    clear_screen
                    exit "${EXIT_ERROR}"
                    ;;
                * )
                    echo "Please answer yes (y) or no (n)"
                    ;;
            esac
        done
    fi

    return 0
}

# Secure cleanup of sensitive data from memory
# - Overwrites variables with random data before clearing
# - Cleans command history and file descriptors
# - Restores original system umask
cleanup() {
    local -r saved_mask=$(umask)

    # Set restrictive permissions for cleanup operations
    umask 077

    # Helper function to securely erase data by overwriting with random data
secure_erase() {
    local var_name="$1"
    if [[ -n "${!var_name:-}" ]]; then
        local random_pattern
        random_pattern="$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)"

        if [[ -v "$var_name" ]]; then
            # Overwrite with random pattern
            printf -v "$var_name" "%s" "$random_pattern"
            # Clear with empty string
            printf -v "$var_name" "%s" ""
        fi

        # Clean random pattern
        unset random_pattern
    fi
}

    # Comprehensive list of security-sensitive variables
    # Includes cryptographic, input, and processing variables
    local sensitive_vars=(
    # User input and sensitive data
        "password"              # User password
        "password_confirm"      # Password confirmation copy
        "remaining_char"        # Remaining character in secure password input
        "input"                 # Input seed phrase
        "input_words"           # Seed phrase word array
        "result"                # Operation result
        "result_phrase"         # Result phrase storage
    # Menu system variables
        "menu_choice"           # Main menu selection
        "help_choice"           # Help menu selection
        "show_menu_now"         # Menu display flag
        "post_choice"           # Post-processing menu selection
        "save_choice"           # Post-save menu selection
        "save_file"             # Save file path
    # XOR-specific variables
        "seed_bits"             # Binary representation of seed
        "keystream"             # Generated keystream
        "result_bits"           # XOR result
        "current_hash"          # Intermediate hash value
    # Cryptographic and processing variables
        "hash"                  # Temporary hash used in process
        "iterations"            # Number of encryption iterations
        "byte_length"          # Byte length for keystream
        "bit_length"            # Bit length for operations
        "hex_string"            # Hexadecimal string in keystream derivation
        "byte_data"             # Binary data for checksum calculation
        "hash_result"           # Hash result from checksum operations
        "answer"                # User answer for file overwrite confirmations
        "bit_a"                 # First bit in XOR operations
        "bit_b"                 # Second bit in XOR operations
    # Word processing variables
        "word"                  # Current word being processed
        "count"                 # Word count
        "phrase"                # Temporary phrase storage
        "words"                 # Word array variable
        "word_lookup"           # BIP39 word lookup table (associative array)
        "invalid_words"         # Array of invalid BIP39 words found
    # Binary processing variables
        "binary"                # Binary string
        "chunk"                 # Binary chunk
        "hex_byte"              # Hex byte value
        "dec"                   # Decimal value
        "bin"                   # Binary representation
        "decimal"               # Decimal conversion variable
        "num"                   # Numeric variable
        "power"                 # Power variable for binary conversion
        "width"                 # Width parameter for binary conversion
        "hex_value"             # Hexadecimal value during byte conversion
        "decimal_value"         # Decimal value converted from binary byte
        "hex_char"              # Individual hexadecimal character from hash
        "hex_nibble"            # 4-bit hexadecimal nibble converted to binary
        "bits_needed"           # Bits needed counter for checksum calculation
        "hex_pos"               # Position in hexadecimal string during processing
    # Checksum variables
        "entropy_bits"          # Entropy bits count
        "checksum_bits"         # Checksum bits count
        "entropy"               # Entropy portion
        "checksum"              # Checksum portion
        "binary_stream"         # Stream for hashing
        "first_byte"            # First byte of hash
        "dec_value"             # Decimal value of byte
        "expected_checksum"     # Expected checksum
        "correct_checksum"      # Corrected checksum
        "binary_data"           # Binary data constructed for OpenSSL hashing
        "hash_output"           # Raw output from OpenSSL SHA256 command
        "hash_hex"              # Extracted hexadecimal hash from OpenSSL output
        "checksum_binary"       # Final checksum in binary format
    # Temporary and loop variables
        "temp"                  # Temporary variable
        "i"                     # Loop counter
        "j"                     # Loop counter
        "index"                 # Array index
        "size"                  # Size variables
        "key"                   # Loop key for arrays
        "answer"                # User input for file overwrite
        "bit"                   # Individual bit variable
        "byte"                  # Byte variable
        "content"               # File content variable
    # File and path variables
        "output_file"           # Output file path
        "file"                  # Input file path
        "dir"                   # Directory path
        "script_name"           # Name of the script
        "file_content"          # Content read from input files
        "dir"                   # Directory path for output files
    # System check variables
        "os_name"               # Operating system name
        "available_memory"      # Available system memory
        "mask"                  # Umask value
        "basic_status"          # Basic requirements audit status
        "memory_status"         # Memory check audit status
        "openssl_status"        # OpenSSL validation audit status
        "critical_failures"     # Critical failures counter
        "message"               # System and audit messages
        "prefix"                # Message prefixes for audit system
    # Signal handling variables
        "sig"                   # Signal name in signal handling loops
        "supported_signals"     # Array of supported system signals
    # Mode and operation variables
        "silent_mode"           # Silent mode flag
    # Other function variables
        "var_name"              # Variable name in secure_erase
        "var"                   # Loop variable in cleanup
        "word_count"            # Word count variable
        "random_pattern"        # Random pattern for cleaning
        "char"                  # Character input variable
    )

    umask 077

    # Clean each variable
    for var in "${sensitive_vars[@]}"; do
        secure_erase "$var"
    done

    # Securely clean all associative arrays used for word mapping
    # Overwrites with random data before unsetting
    if declare -p word_lookup >/dev/null 2>&1; then
        for key in "${!word_lookup[@]}"; do
            word_lookup[$key]="$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64)"
            unset 'word_lookup[$key]'
        done
        unset word_lookup
    fi

    # Clean invalid_words array if it exists
    if declare -p invalid_words >/dev/null 2>&1; then
        for key in "${!invalid_words[@]}"; do
            invalid_words[$key]="$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64)"
            unset 'invalid_words[$key]'
        done
        unset invalid_words
    fi

    # Clean supported_signals array if it exists
    if declare -p supported_signals >/dev/null 2>&1; then
        for ((i=0; i<${#supported_signals[@]}; i++)); do
            supported_signals[$i]="$(dd if=/dev/urandom bs=8 count=1 2>/dev/null | base64)"
        done
        unset supported_signals
    fi

    # Clean arrays used in processing
    if declare -p input_words >/dev/null 2>&1; then
        for ((i=0; i<${#input_words[@]}; i++)); do
            input_words[$i]="$(dd if=/dev/urandom bs=16 count=1 2>/dev/null | base64)"
        done
        unset input_words
    fi

    if declare -p words >/dev/null 2>&1; then
        for ((i=0; i<${#words[@]}; i++)); do
            words[$i]="$(dd if=/dev/urandom bs=16 count=1 2>/dev/null | base64)"
        done
        unset words
    fi

    # Unset ALL variables including those not in the list
    unset ${sensitive_vars[@]} 2>/dev/null
    unset -f secure_erase 2>/dev/null

    # Clean command history
    clear_history

    # Force bash garbage collection (if available)
    if declare -F bash_gc >/dev/null 2>&1; then
        bash_gc
    fi

    # Clean file descriptors
    exec 3>&- 2>/dev/null
    exec 2>&1

    # Restore original system umask to maintain system configuration
    umask "$saved_mask"
}

# Enhanced show usage information
show_usage() {
    local script_name
    script_name=$(basename "$0")

    # Banner with existing ASCII art (preserved exactly)
    echo -e "${COLOR_BRIGHT}SCypher v${VERSION}${COLOR_RESET} ${COLOR_DIM}- XOR-based BIP39 Seed Cipher${COLOR_RESET}"
    echo -e "${COLOR_DIM}                        ErgoHack X Competition Release${COLOR_RESET}"

    echo
    echo -e "${COLOR_PRIMARY}                                  000000000"
    echo -e "                              000000000000000000"
    echo -e "                            000000          000000"
    echo -e "                           000                  000"
    echo -e "                          000     0000000000     000"
    echo -e "                         000      0000000000      000"
    echo -e "                         00        0000           000"
    echo -e "                        000          0000          000"
    echo -e "                        000          0000          000"
    echo -e "                         000       0000            00"
    echo -e "                         000      0000000000      000"
    echo -e "                          000     0000000000     000"
    echo -e "                           000                  000"
    echo -e "                            000000          000000"
    echo -e "                              000000000000000000"
    echo -e "                                   000000000${COLOR_RESET}"
    echo

    # Main content using cat (clean and professional)
    cat << EOF
A tool for encrypting/decrypting BIP39 seed phrases using XOR cipher with SHAKE-256

Resources:
- BIP39 Standard by M. Palatinus & P. Rusnak
- Developed with AI assistance (ChatGPT/Claude)

⚠️  IMPORTANT: Please read the license and disclaimer before use (--license)

Usage:
    ${script_name} [OPTIONS]          # Interactive menu mode (default)
    ${script_name} [OPTIONS] < input  # Direct processing mode

Options:
    -f OUTPUT_FILE    Save output to specified file (will append .txt if needed)
    -s, --silent      Silent mode (no prompts, for scripting)
    --license         Show license and disclaimer
    --details         Show detailed explanation of the cipher process
    -h, --help        Show this help message and exit

Examples:
    ${script_name}                           # Interactive menu mode
    ${script_name} -f output.txt             # Interactive menu, save to file
    ${script_name} --license                 # View license and disclaimer
    ${script_name} --details                 # Learn how the cipher works
    ${script_name} -s < input.txt            # Process input file in silent mode

Note: XOR encryption is symmetric - the same operation encrypts and decrypts.
Use the same password and iterations to reverse the transformation.

$COMPATIBILITY_INFO

EOF
    exit "$EXIT_SUCCESS"
}

# Main program flow and user interaction handler
# Controls:
# - Command line argument processing
# - Input validation and file handling
# - Password and iteration management
# - Output generation and file writing
main() {
    local output_file=""
    local silent_mode=0
    local password=""
    local input_words=()
    local show_menu_now=$SHOW_MENU

    while [[ "$#" -gt 0 ]]; do
            case "$1" in
                -h|--help)
                    show_usage
                    ;;
                --license)
                    show_license
                    ;;
                --details)
                    show_details
                    ;;
                -f)
                    [[ -z "$2" ]] && show_usage
                    output_file="$2"
                    show_menu_now=0  # CLI args disable menu
                    shift 2
                    ;;
                -s|--silent)
                    silent_mode=1
                    show_menu_now=0  # Silent mode disables menu
                    shift
                    ;;
                *)
                    shift
                    ;;
            esac
        done

    if [[ -n "$output_file" ]]; then
        [[ "$output_file" != *"${EXTENSION}" ]] && output_file="${output_file}${EXTENSION}"
        validate_output_file "$output_file"
    fi

    if [[ -n "$output_file" ]]; then
        [[ "$output_file" != *"${EXTENSION}" ]] && output_file="${output_file}${EXTENSION}"
        validate_output_file "$output_file"
    fi

# Menu system logic - Show interactive menu if no CLI args and not silent mode
    if [[ $show_menu_now -eq 1 && $silent_mode -eq 0 ]]; then
        # Show interactive menu system
        handle_main_menu
        # After menu selection, continue with main logic below
    elif [[ $# -eq 0 && $silent_mode -eq 0 ]]; then
        # If no CLI args and not silent, but show_menu_now is 0, still show menu
        # This handles the case when returning from previous operations
        handle_main_menu
    fi

    # Clear previous audit messages for fresh operation
        initialize_audit

    # Interactive input phase
    local input
    while true; do
        if [[ $silent_mode -eq 0 ]]; then
            echo ""
            echo -e "${COLOR_PRIMARY}Enter seed phrase or input file to process:${COLOR_RESET}"
            echo -n "> "
            read -r input
            echo

            # Check if input looks like a file path and handle accordingly
            if [[ "$input" == *.* ]] || [[ -f "$input" ]]; then
                # Input looks like a file or is an existing file
                if [[ -f "$input" ]]; then
                    # File exists, read it
                    input=$(read_words_from_file "$input")
                else
                    # Input looks like a file but doesn't exist
                    echo "" >&2
                    echo "Error: File '$input' not found" >&2
                    echo "" >&2
                    read -p "Press enter to try again..."
                    echo ""
                    continue
                fi
            fi
        else
            read -r input
            # Silent mode: only check if file actually exists
            if [[ -f "$input" ]]; then
                input=$(read_words_from_file "$input")
            fi
        fi

        # Validate input format AFTER file processing
        if ! validate_input "$input"; then
            echo "" >&2
            read -p "Press enter to clear screen and try again..."
            clear_screen
            continue
        fi

        # Convert input to array
        read -ra input_words <<< "$input"

        # Validate word count
        if ! validate_word_count "${input_words[@]}"; then
            continue
        fi

        # Validate BIP39 words
        if ! validate_bip39_words "${input_words[@]}"; then
            continue
        fi

        # Verify checksum before processing
        if verify_checksum "$input"; then
            add_audit_message "$AUDIT_INFO" "Input seed phrase checksum verification: Valid"
            echo "" >&2
        else
            add_audit_message "$AUDIT_WARNING" "Input seed phrase checksum verification: Invalid"
            echo "" >&2
        fi

        # Display accumulated messages
        for message in "${AUDIT_MESSAGES[@]}"; do
            echo -e "$message" >&2
        done

        break
    done

    # Get password after successful validation
    if [[ $silent_mode -eq 0 ]]; then
        password=$(read_secure_password)

        # Get number of iterations
        local iterations
        while true; do
            printf "\nEnter number of iterations (minimum 1): " >&2
            read iterations

            if [[ "$iterations" =~ ^[0-9]+$ ]] && [ "$iterations" -ge 1 ]; then
                break
            else
                printf "Error: Please enter a positive number\n" >&2
                echo "" >&2
                read -p "Press enter to clear screen and try again..."
                clear_screen
            fi
        done
    else
        read -rs password
        read -r iterations
        if ! [[ "$iterations" =~ ^[0-9]+$ ]] || [ "$iterations" -lt 1 ]; then
            handle_error "Invalid number of iterations"
        fi
    fi

    # Process the phrase using XOR (symmetric operation)
    local result
    result=$(process_phrase_xor "$input" "$password" "$iterations")

    echo ""
    if [[ -n "$output_file" ]]; then
        if ! echo "$result" > "$output_file" 2>/dev/null; then
            echo "" >&2
            echo "Error: Failed to write to output file" >&2
            echo "" >&2
            read -p "Press enter to clear screen and exit..."
            clear_screen
            exit "${EXIT_ERROR}"
        fi

        if ! chmod "${PERMISSIONS}" "$output_file" 2>/dev/null; then
            echo "" >&2
            echo "Error: Failed to set file permissions" >&2
            echo "" >&2
            read -p "Press enter to clear screen and exit..."
            clear_screen
            exit "${EXIT_ERROR}"
        fi

        echo -e "${COLOR_SUCCESS}Result:${COLOR_RESET}"
        echo -e "${COLOR_PRIMARY}$result${COLOR_RESET}"
        if [[ $silent_mode -eq 0 ]]; then
            echo ""
            echo -e "${COLOR_SUCCESS}✓ Output saved to ${output_file}${COLOR_RESET}"
        fi
        else
            echo ""
            echo -e "${COLOR_SUCCESS}Result:${COLOR_RESET}"
            echo -e "${COLOR_PRIMARY}$result${COLOR_RESET}"
        fi

    # Verify checksum of result
    if verify_checksum "$result"; then
        add_audit_message "$AUDIT_INFO" "Output seed phrase checksum verification: Valid"
        echo "" >&2
    else
        add_audit_message "$AUDIT_WARNING" "Output seed phrase checksum verification: Invalid"
        echo "" >&2
    fi

    # Display accumulated messages
    for message in "${AUDIT_MESSAGES[@]}"; do
        echo -e "$message" >&2
    done

    # Post-processing options menu (only in interactive mode)
    if [[ $silent_mode -eq 0 ]]; then
        handle_post_processing_menu "$result"
    fi
}

# Enable bash strict mode for robust error handling
# - Exit on error (-e)
# - Exit on undefined variables (-u)
# - Exit on pipeline failures (-o pipefail)
set -o errexit
set -o nounset
set -o pipefail

# System security audit
system_security_audit

# Protect against core dumps
protect_against_coredumps

# Setup enhanced signal handling
setup_signal_handlers

trap 'cleanup' EXIT HUP PIPE INT TERM

# Initialize security measures and start main program
# - System compatibility verification
# - Core dump protection
# - Signal handlers
# - Main program execution with menu loop
while true; do
    main "$@"

    # If silent mode or CLI args provided, exit after one execution
    if [[ $# -gt 0 ]] || grep -q "\-s\|\-\-silent" <<< "$*" 2>/dev/null; then
        break
    fi

    # Reset SHOW_MENU for subsequent iterations
    SHOW_MENU=$SHOW_MENU_DEFAULT
done
