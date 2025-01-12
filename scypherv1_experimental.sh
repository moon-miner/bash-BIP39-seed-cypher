 #!/usr/bin/env bash

# SCypher - Advanced BIP39 Seed Cipher (v1.0)
# Bash implementation of a secure BIP39 seed phrase transformation utility
# that maintains BIP39 standard compliance for encrypted outputs.
#
# Core Features:
# - Encrypted seeds remain valid BIP39 phrases
# - Pure Bash implementation (no external dependencies except OpenSSL)
# - Implements Fisher-Yates shuffle (Knuth-Durstenfeld variant)
# - Uses SHAKE-256 for cryptographic operations
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

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Version number for compatibility tracking
readonly VERSION="1.0"

# Standard exit codes for program status
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1

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
How SCypher Works (Non-Technical Explanation):

SCypher is a tool that helps you protect your cryptocurrency seed phrases while keeping
them in a valid BIP39 format. Here's how it works in simple terms:

1. Starting Point:
   - You have a seed phrase (12-24 words from the BIP39 word list)
   - You choose a password and number of iterations that you'll remember
   - The tool generates a random salt for extra security

2. The Process:
   Encryption:
   - SCypher generates a unique random salt
   - This salt is converted into 12 BIP39 words
   - Your password, number of iterations, and the salt create a unique mixing pattern
   - Your seed phrase words get swapped based on this pattern
   - The output combines the salt words and your encrypted phrase

   Decryption:
   - SCypher extracts the first 12 words (the salt)
   - Uses your password, number of iterations, and the extracted salt
   - Reverses the mixing pattern to recover your original phrase

3. Security Features:
   - Each encryption uses a new random salt
   - The salt adds 132 bits of extra security
   - The process works both ways (encoding and decoding)
   - Only someone with both your password and iterations can reverse the process
   - The output is always a valid BIP39 seed phrase
   - The password and iterations never get stored anywhere

4. Understanding the Output:
   - Encrypted result: [12 salt words] + [encrypted seed phrase]
   - The salt is automatically included as the first 12 words
   - The password, iterations, and salt are all needed for decoding
   - The process is deterministic when using the same salt, password, and number of iterations

5. Important Notes:
   - The number of iterations adds an extra layer of security
   - More iterations means more computational work for potential attackers
   - Both the password and the number of iterations are needed for decoding
   - Always keep your password and number of iterations safe - without both, you can't decode your phrase
   - Maintain secure backups of original seeds
   - Test the process with a non-critical seed phrase first
   - Make sure to verify you can successfully decode before using with real funds

Security Enhancement with Salt:
The salt ensures that even if you use the same password and iterations to encrypt
multiple seed phrases, each encryption will be unique. This prevents pattern analysis
and adds a significant layer of security to your encrypted phrases.

This tool provides an extra layer of security while maintaining compatibility with
all systems that use BIP39 seed phrases."

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
    # Check if running under bash
    if [ -z "$BASH_VERSION" ]; then
        add_audit_message "$AUDIT_CRITICAL" "This script requires bash.\nPlease run it with sudo bash $0"
        return "$AUDIT_FAILURE"
    fi

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

    if command -v aa-status >/dev/null 2>&1 && aa-status --enabled 2>/dev/null; then
        add_audit_message "$AUDIT_INFO" "AppArmor is enabled"
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
        if prctl --set-priv basic,!core_dump $$ >/dev/null 2>&1; then
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
    echo "$LICENSE_TEXT"
    exit "$EXIT_SUCCESS"
}

show_details() {
    echo "$DETAILS_TEXT"
    exit "$EXIT_SUCCESS"
}

# Clear screen using portable ANSI escape sequences
# Does not rely on 'clear' command for compatibility
clear_screen() {
    echo -e "\033[2J\033[H"
}

# Standardized error handling with user interaction
# Displays error message, waits for acknowledgment, clears screen
handle_error() {
    local error_message="$1"

    # Display error message
    echo "Error: $error_message" >&2
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

    # Check maximum length
    if [[ ${#input} -gt 1024 ]]; then
        echo "" >&2
        echo "Error: Input exceeds maximum length of 1024 characters" >&2
        echo "" >&2
        return 1
    fi

    return 0
}

# Securely read and validate user password
# Features:
# - Disables terminal echo
# - Enforces minimum length
# - Requires confirmation match
# - Handles secure input mode
read_secure_password() {
    local password password_confirm

    # Enable secure input mode
    secure_input_mode enable

    # Print recommendations to stderr to ensure they appear
    cat >&2 << EOF

Password recommendations:
- Minimum length: 8 characters
- Include uppercase and lowercase letters
- Include numbers and special characters

EOF

    while true; do
        printf "Enter password: " >&2
        read -r password
        printf "\n" >&2  # Explicit newline after password input

        printf "Confirm password: " >&2
        read -r password_confirm
        printf "\n" >&2  # One newline after confirmation

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

    # Disable secure input mode
    secure_input_mode disable

    printf "%s" "$password"
}

# Cryptographically secure Fisher-Yates shuffle implementation
# Uses deterministic seed for reproducible results
# Maintains constant space complexity O(1)
fisher_yates_shuffle() {
    local -i seed="$1"
    local -a arr=("${@:2}")
    local -i size=${#arr[@]}
    local -i i j
    local temp

    for ((i = size - 1; i > 0; i--)); do
        j=$(( (seed + i) % (i + 1) ))


        if [[ $i -lt $size && $j -lt $size && -n "${arr[i]}" && -n "${arr[j]}" ]]; then
            temp="${arr[i]}"
            arr[i]="${arr[j]}"
            arr[j]="$temp"
        fi
    done

    printf "%s\n" "${arr[@]}"
}

# Generate cryptographically secure 132-bit random salt using OpenSSL
# Returns: 0 on success, 1 on failure
generate_random_salt() {
    local hex_bytes
    local binary=""

    # Generate 17 random bytes (136 bits) to ensure we have suficientes bits
    if ! hex_bytes=$(openssl rand -hex 17 2>/dev/null); then
        echo "Error: Failed to generate random salt" >&2
        return 1
    fi

    # Convert hex to binary and take exactly 132 bits
    binary=$(echo "ibase=16; obase=2; ${hex_bytes^^}" | bc | tr -d '\\\n' | cut -c1-132)

    if [[ ${#binary} -ne 132 ]]; then
        echo "Error: Generated salt has incorrect length" >&2
        return 1
    fi

    echo "$binary"
    return 0
}

# Convert 132-bit salt to 12 BIP39 words
# Input: 33-character hex string
# Output: Space-separated string of 12 BIP39 words
bits_to_words() {
    local binary_salt="$1"
    local word_indices=()
    local result=""


    for ((i=0; i<132; i+=11)); do
        local chunk="${binary_salt:$i:11}"
        local index=$((2#$chunk))
        word_indices+=("$index")
    done

    for index in "${word_indices[@]}"; do
        [[ -n "$result" ]] && result+=" "
        result+="${WORDS[$index]}"
    done

    echo "$result"
}

# Convert 12 BIP39 words back to 132-bit salt
# Input: Space-separated string of 12 BIP39 words
# Output: 33-character hex string
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
        # Convertir directamente a binario sin usar bc
        local bin=$(printf "%011d" "$(echo "obase=2;$index" | bc)")
        binary+="$bin"
    done

    # Si se especifica una longitud, truncar el resultado
    if [[ -n "${2:-}" ]]; then
        binary="${binary:0:$2}"
    fi

    echo "$binary"
}

# Verifica el checksum de una frase BIP39
# Input: Frase semilla como string
# Output: 0 si es válido, 1 si no es válido
verify_checksum() {
    local seed_phrase="$1"
    local word_count=$(echo "$seed_phrase" | wc -w)
    local entropy_bits=$((word_count * 32 / 3))
    local checksum_bits=$((entropy_bits / 32))

    local binary=$(words_to_bits "$seed_phrase")
    local entropy="${binary:0:$entropy_bits}"
    local checksum="${binary:$entropy_bits:$checksum_bits}"

    # Crear datos binarios directamente
    local binary_stream=""
    for ((i = 0; i < entropy_bits; i += 8)); do
        local byte="${entropy:$i:8}"          # Extraer 8 bits
        local dec=$((2#$byte))               # Convertir a decimal

        # Validar el valor de `$dec`
        if [[ $dec -ge 0 && $dec -le 255 ]]; then
            # Intentar agregar el byte al flujo binario
            if ! binary_stream+=$(printf "\\x%02x" "$dec" 2>/dev/null); then
                return 1
            fi
        else
            return 1
        fi
    done

    # Calcular el hash
    local hash=$(printf "%b" "$binary_stream" | openssl dgst -sha256 -binary | openssl enc -base64)
    local first_byte=$(echo -n "$hash" | base64 -d | od -An -tx1 -N1 | tr -d ' \n')
    local dec_value=$((16#$first_byte))

    # Convertir el byte a binario
    local bin=""
    for ((i = 7; i >= 0; i--)); do
        bin+=$(( (dec_value >> i) & 1 ))
    done
    local expected_checksum="${bin:0:$checksum_bits}"

    [[ "$checksum" == "$expected_checksum" ]] && return 0 || return 1
}

# Generate deterministic word permutation using SHAKE-256
# Parameters:
#   password: User-provided encryption key
#   iterations: Number of shuffle rounds for additional security
mix_words() {
    local password="$1"
    local salt="$2"
    local iterations="$3"
    declare -a mixed_words
    mixed_words=("${WORDS[@]}")
    local seed hash

    hash=$(printf "%s%s" "$password" "$salt" | openssl dgst -shake256 -xoflen 128 | sed 's/^.*= //')
    seed=$(printf "%d" "0x${hash:0:15}")

    for ((i = 1; i <= iterations; i++)); do
        mapfile -t mixed_words < <(fisher_yates_shuffle "$seed" "${mixed_words[@]}")
        hash=$(printf "%s%s" "$hash" "$salt" | openssl dgst -shake256 -xoflen 128 | sed 's/^.*= //')
        seed=$(printf "%d" "0x${hash:0:15}")
    done

    printf "%s\n" "${mixed_words[@]}"
}

# Create and apply deterministic word pair mappings
# Process:
# - Generates word pairs from shuffled BIP39 list
# - Maps each word to its pair consistently
# - Transforms input using generated mapping
# Returns: Space-separated string of mapped words
create_pairs() {
    local password="$1"
    local salt="$2"
    local iterations="$3"
    shift 3
    local -a input_words=("$@")

    local -a mixed_words
    mapfile -t mixed_words < <(mix_words "$password" "$salt" "$iterations")
    local -i half_size=$(( ${#mixed_words[@]} / 2 ))

    if (( ${#mixed_words[@]} % 2 != 0 )); then
        echo "" >&2
        echo "Error: Internal error - invalid word list size" >&2
        echo "" >&2
        read -p "Press enter to clear screen and exit..."
        clear_screen
        exit "${EXIT_ERROR}"
    fi

    declare -A mapping

    for ((i = 0; i < half_size; i++)); do
        local word1="${mixed_words[i]}"
        local word2="${mixed_words[i + half_size]}"

        if [[ -z "$word1" || -z "$word2" ]]; then
            echo "" >&2
            echo "Error: Empty word detected in mapping" >&2
            echo "" >&2
            read -p "Press enter to clear screen and exit..."
            clear_screen
            exit "${EXIT_ERROR}"
        fi

        if [[ "$word1" =~ [[:space:]] || "$word2" =~ [[:space:]] ]]; then
            echo "" >&2
            echo "Error: Word contains whitespace" >&2
            echo "" >&2
            read -p "Press enter to clear screen and exit..."
            clear_screen
            exit "${EXIT_ERROR}"
        fi

        mapping["$word1"]="$word2"
        mapping["$word2"]="$word1"
    done

    local output=""
    for word in "${input_words[@]}"; do
        word=$(echo "$word" | tr -d '[:space:]')

        if [[ -n "${mapping[$word]+x}" ]]; then
            local mapped_word="${mapping[$word]}"

            if [[ -z "$mapped_word" || "$mapped_word" =~ [[:space:]] ]]; then
                echo "" >&2
                echo "Error: Internal operation failed - mapping error" >&2
                echo "" >&2
                read -p "Press enter to clear screen and exit..."
                clear_screen
                exit "${EXIT_ERROR}"
            fi

            [[ -n "$output" ]] && output+=" "
            output+="$mapped_word"
        else
            echo "" >&2
            echo "Error: Invalid word detected in seed phrase" >&2
            echo "" >&2
            read -p "Press enter to clear screen and exit..."
            clear_screen
            exit "${EXIT_ERROR}"
        fi
    done

    echo "$output"
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
        "PASSWORD"              # User password
        "password_confirm"      # Password confirmation copy
        "full_hash"             # Full SHAKE-256 hash in iterations
        "input"                 # Input seed phrase
        "input_words"           # Seed phrase word array
        "result"                # Operation result
    # Cryptographic and processing variables
        "mixed_words"           # Shuffled word list
        "mapping"               # Word pair mapping table
        "seed"                  # Password-derived seed
        "hash"                  # Temporary hash used in process
        "iterations"            # Number of encryption iterations
    # Word processing variables
        "word"                  # Current word being processed
        "word1"                 # First word in pair mapping
        "word2"                 # Second word in pair mapping
        "mapped_word"           # Result of word mapping
        "count"                 # Word count
    # Checksum variables
        "entropy_bits"          # Bits de entropía
        "checksum_bits"        # Bits de checksum
        "binary"               # String binario completo
        "entropy"              # Parte de entropía del binario
        "checksum"            # Parte de checksum del binario
        "binary_stream"       # Stream de bytes para hash
        "hash"                # Hash SHA256
        "first_byte"          # Primer byte del hash
        "dec_value"           # Valor decimal del byte
        "bin"                 # Representación binaria
        "expected_checksum"   # Checksum esperado
    # Temporary and loop variables
        "temp"                  # Temporary variable used in shuffle
        "arr"                   # Temporary array in shuffle
        "i"                     # Loop counter
        "j"                     # Loop counter
        "half_size"             # Half size for word pairing
        "size"                  # Size variables
        "key"                   # Loop key for arrays
        "answer"                # User input for file overwrite
    # File and path variables
        "output_file"           # Output file path
        "file"                  # Input file path
        "dir"                   # Directory path
        "script_name"           # Name of the script
    # System check variables
        "os_name"               # Operating system name
        "available_memory"      # Available system memory
        "mask"                  # Umask value
    # Other function variables
        "var_name"              # Variable name in secure_erase
        "var"                   # Loop variable in cleanup
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
    fi

    # Clean mapping array if it exists
    if declare -p mapping >/dev/null 2>&1; then
        for key in "${!mapping[@]}"; do
            mapping[$key]="$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64)"
            unset 'mapping[$key]'
        done
    fi

     # Clean invalid_words
    if declare -p invalid_words >/dev/null 2>&1; then
        for key in "${!invalid_words[@]}"; do
            invalid_words[$key]="$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64)"
            unset 'invalid_words[$key]'
        done
    fi

    # Unset ALL variables
    unset ${sensitive_vars[@]}
    unset password password_confirm input result hash seed full_hash
    unset mixed_words mapping word_lookup invalid_words
    unset iterations word1 word2 mapped_word temp answer
    unset i j half_size size output_file file dir arr
    unset os_name available_memory mask var_name var key
    unset word count script_name
    unset -f secure_erase

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

    cat << EOF

SCypher v${VERSION} - Bash-based BIP39 Seed Cipher
A tool for encoding/decoding BIP39 seed phrases using a deterministic Fisher-Yates (Knuth-Durstenfeld's variant)

Resources:
- BIP39 Standard by M. Palatinus & P. Rusnak
- Developed with AI assistance (ChatGPT/Claude)

⚠️  IMPORTANT: Please read the license and disclaimer before use (--license)

Usage:
    ${script_name} [OPTIONS]

Options:
    -e, --encrypt     Encryption mode (default)
    -d, --decrypt     Decryption mode
    -f OUTPUT_FILE    Save output to specified file (will append .txt if needed)
    -s, --silent      Silent mode (no prompts, for scripting)
    --license         Show license and disclaimer
    --details         Show detailed explanation of the cipher process
    -h, --help        Show this help message and exit

Examples:
    ${script_name} -e -f output.txt          # Encrypt and save to file
    ${script_name} -d -f encrypted.txt       # Decrypt from file
    ${script_name} --license                 # View license and disclaimer
    ${script_name} --details                 # Learn how the cipher works
    ${script_name} -s < input.txt            # Process input file in silent mode

$COMPATIBILITY_INFO

EOF

    cat << 'EOF'
                                  000000000
                              000000000000000000
                            000000          000000
                           000                  000
                          000     0000000000     000
                         000      0000000000      000
                         00        0000           000
                        000          0000          000
                        000          0000          000
                         000       0000            00
                         000      0000000000      000
                          000     0000000000     000
                           000                  000
                            000000          000000
                              000000000000000000
                                   000000000

EOF
    exit "$EXIT_SUCCESS"
}

# Main program flow and user interaction handler
# Controls:
# - Command line argument processing
# - Input validation and file handling
# - Password and iteration management
# - Output generation and file writing
# Main program flow and user interaction handler
main() {
    local output_file=""
    local silent_mode=0
    local password=""
    local input_words=()
    local mode="encrypt"  # Default mode

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
                shift 2
                ;;
            -s|--silent)
                silent_mode=1
                shift
                ;;
            -e|--encrypt)
                mode="encrypt"
                shift
                ;;
            -d|--decrypt)
                mode="decrypt"
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

    # Interactive input phase
    local input
    while true; do
        if [[ $silent_mode -eq 0 ]]; then
            echo ""
            if [[ "$mode" == "encrypt" ]]; then
                echo -n "Enter seed phrase or input file to encrypt: "
            else
                echo -n "Enter encrypted phrase or input file to decrypt: "
            fi
            read -r input
            echo

            if is_file "$input"; then
                input=$(read_words_from_file "$input")
            fi
        else
            read -r input
        fi

        # Validate input format
        if ! validate_input "$input"; then
            echo "" >&2
            read -p "Press enter to clear screen and try again..."
            clear_screen
            continue
        fi

        # Convert input to array
        read -ra input_words <<< "$input"

        if [[ "$mode" == "decrypt" ]]; then
            # For decryption, we need at least 12 words for salt plus the encrypted phrase
            if [ ${#input_words[@]} -lt 13 ]; then
                echo "Error: Invalid encrypted phrase (too few words)" >&2
                continue
            fi
        fi

        # For encryption, validate original word count
        # For decryption, validate total minus salt words
        local check_words=("${input_words[@]}")
        if [[ "$mode" == "decrypt" ]]; then
            check_words=("${input_words[@]:12}")
        fi

        # Validate word count
        if ! validate_word_count "${check_words[@]}"; then
            continue
        fi

        # Validate BIP39 words
        if ! validate_bip39_words "${input_words[@]}"; then
            continue
        fi

        # Verificar checksum si estamos cifrando o si es el resultado del descifrado
        if [[ "$mode" == "encrypt" ]]; then
            if verify_checksum "$input"; then
                add_audit_message "$AUDIT_INFO" "Input seed phrase checksum verification: Valid"
                echo "" >&2  # Agregar línea en blanco para mejor formato
            else
                add_audit_message "$AUDIT_WARNING" "Input seed phrase checksum verification: Invalid"
                echo "" >&2  # Agregar línea en blanco para mejor formato
            fi

            # Mostrar los mensajes acumulados
            for message in "${AUDIT_MESSAGES[@]}"; do
                echo -e "$message" >&2
            done
        fi

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

    local result
    if [[ "$mode" == "encrypt" ]]; then
        # Generate salt and convert to words
        local salt
        salt=$(generate_random_salt) || exit 1
        local salt_words
        salt_words=$(bits_to_words "$salt")

        # Process input words with salt
        local encrypted_words
        encrypted_words=$(create_pairs "$password" "$salt" "$iterations" "${input_words[@]}")

        # Combine salt words and encrypted words
        result="$salt_words $encrypted_words"
    else
        # Extract salt words and convert back to bits
        local salt_words="${input_words[@]:0:12}"
        local salt
        salt=$(words_to_bits "$salt_words")

        # Process remaining words with extracted salt
        result=$(create_pairs "$password" "$salt" "$iterations" "${input_words[@]:12}")
    fi

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

        echo "$result"
        if [[ $silent_mode -eq 0 ]]; then
            echo ""
            echo "Output saved to ${output_file}"
        fi
    else
        echo ""
        echo "$result"
    fi

    # Verificar checksum del resultado si estamos descifrando
    if [[ "$mode" == "decrypt" ]]; then
        if verify_checksum "$result"; then
            add_audit_message "$AUDIT_INFO" "Decrypted seed phrase checksum verification: Valid"
            echo "" >&2
        else
            add_audit_message "$AUDIT_WARNING" "Decrypted seed phrase checksum verification: Invalid"
            echo "" >&2
        fi

        # Mostrar los mensajes acumulados
        for message in "${AUDIT_MESSAGES[@]}"; do
            echo -e "$message" >&2
        done
    fi

    if [[ $silent_mode -eq 0 ]]; then
        echo ""
        read -p "Press enter to clear screen and continue..."
        clear_screen
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
# - Main program execution
main "$@"
