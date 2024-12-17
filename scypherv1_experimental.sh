#!/bin/bash

# SCypher - Bash-based BIP39 Seed Cipher v1.0
# A tool for encoding/decoding BIP39 seed phrases using a deterministic Fisher-Yates (Knuth-Durstenfeld's variant)
#
# Resources:
# - BIP39 Standard by M. Palatinus & P. Rusnak
# - Developed with AI assistance (ChatGPT/Claude)
#
# System Requirements:
# - Bash 4.0 or higher (for associative arrays)
# - sha256sum command (usually part of coreutils)
# - Basic POSIX utilities (read, printf, etc.)
# - At least 100MB of available RAM
# - Write permissions in the output directory
# - Terminal with UTF-8 support for ASCII art

# Version
readonly VERSION="1.0"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1

# File and permission constants
readonly PERMISSIONS=600
readonly EXTENSION=".txt"

# Validation constants
readonly MIN_BASH_VERSION=4
readonly MIN_PASSWORD_LENGTH=1
readonly VALID_WORD_COUNTS=(12 15 18 21 24)

# Sistema de logging
declare -r LOG_FILE="/var/log/scypher.log"
declare -r LOG_ERROR=0
declare -r LOG_WARN=1
declare -r LOG_INFO=2
declare -r LOG_DEBUG=3

log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Solo logear si tenemos permisos
    if [[ -w "$(dirname "$LOG_FILE")" ]]; then
        case $level in
            $LOG_ERROR) echo "[$timestamp] ERROR: $message" >> "$LOG_FILE" ;;
            $LOG_WARN)  echo "[$timestamp] WARN:  $message" >> "$LOG_FILE" ;;
            $LOG_INFO)  echo "[$timestamp] INFO:  $message" >> "$LOG_FILE" ;;
            $LOG_DEBUG) [[ "${DEBUG:-}" == "1" ]] && echo "[$timestamp] DEBUG: $message" >> "$LOG_FILE" ;;
        esac
    fi
}

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
   - You choose a password that you'll remember

2. The Process:
   - SCypher takes your password and uses it to create a unique mixing pattern
   - It then pairs up all the words in the BIP39 list in a special way
   - When you input your seed phrase, each word gets swapped with its pair
   - This creates a new, valid seed phrase that looks completely different

3. Security Features:
   - The process works both ways (encoding and decoding)
   - Only someone with your password can reverse the process
   - The output is always a valid BIP39 seed phrase
   - The password never gets stored anywhere

4. Important Notes:
   - The number of iterations adds an extra layer of security
   - More iterations means more computational work for potential attackers
   - Each iteration produces a different encoded phrase
   - Both the password and the number of iterations are needed for decoding
   - Always keep your password safe - without it, you can't decode your phrase
   - Maintain secure backups of original seeds
   - Test the process with a non-critical seed phrase first
   - Make sure to verify you can successfully decode before using with real funds


This tool provides an extra layer of security while maintaining compatibility with
all systems that use BIP39 seed phrases."

# System compatibility information
readonly COMPATIBILITY_INFO="
Dependencies:
- bash (version 4.0 or higher)
- coreutils (for sha256sum)

Installation:
1. Linux: Most distributions include these by default
   If needed: sudo apt-get install coreutils

2. macOS: Install via Homebrew
   brew install bash coreutils

3. Windows (WSL/Cygwin/MSYS2):
   - WSL: Follow Linux instructions
   - Cygwin/MSYS2: Install during setup or via package manager"

# BIP39 wordlist
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

# OS Compatibility Check
check_system_compatibility() {
    local os_name
    os_name=$(uname -s)

    # Verificar requisitos de memoria
    local available_memory=0
    case "$os_name" in
        Linux)
            if ! available_memory=$(free -m | awk '/^Mem:/{print $7}'); then
                log $LOG_WARN "Could not determine available memory"
                echo "Warning: Could not determine available memory" >&2
                available_memory=0
            fi
            ;;
        Darwin)
            if ! available_memory=$(vm_stat | awk '/free/ {gsub(/\./, "", $3); print int($3)*4096/1024/1024}'); then
                log $LOG_WARN "Could not determine available memory"
                echo "Warning: Could not determine available memory" >&2
                available_memory=0
            fi
            ;;
        *)
            log $LOG_WARN "Could not determine available memory on $os_name"
            echo "Warning: Could not determine available memory on $os_name" >&2
            available_memory=0
            ;;
    esac

    if [[ $available_memory -lt 100 ]]; then
        log $LOG_WARN "Less than 100MB of available memory"
        echo "Warning: System has low available memory (${available_memory}MB)" >&2
    fi

    # Verificaciones específicas por OS
    case "$os_name" in
        Linux)
            if ! command -v sha256sum >/dev/null 2>&1; then
                log $LOG_ERROR "sha256sum not found"
                echo "Error: sha256sum not found. Please install GNU coreutils." >&2
                exit "${EXIT_ERROR}"
            fi
            ;;
        Darwin)
            if ! command -v sha256sum >/dev/null 2>&1; then
                if command -v gsha256sum >/dev/null 2>&1; then
                    sha256sum() { gsha256sum "$@"; }
                else
                    log $LOG_ERROR "sha256sum not found on macOS"
                    echo "Error: sha256sum not found. Please install coreutils via Homebrew:" >&2
                    echo "brew install coreutils" >&2
                    exit "${EXIT_ERROR}"
                fi
            fi
            ;;
        MINGW*|CYGWIN*|MSYS*)
            if ! command -v sha256sum >/dev/null 2>&1; then
                log $LOG_ERROR "sha256sum not found on Windows"
                echo "Error: sha256sum not found. Please install GNU coreutils for Windows." >&2
                exit "${EXIT_ERROR}"
            fi
            if [[ "$(printf '\r')" == $'\r' ]]; then
                log $LOG_WARN "Windows line endings detected"
                echo "Warning: Windows line endings detected. This may cause issues." >&2
            fi
            ;;
        *)
            log $LOG_WARN "Untested operating system: $os_name"
            echo "Warning: Untested operating system ($os_name). Proceed with caution." >&2
            ;;
    esac

    if ! locale charmap >/dev/null 2>&1; then
        log $LOG_WARN "Could not determine system locale"
        echo "Warning: Could not determine system locale" >&2
    elif [[ $(locale charmap) != "UTF-8" ]]; then
        log $LOG_WARN "Non-UTF-8 locale detected"
        echo "Warning: Non-UTF-8 locale detected" >&2
    fi

    return 0  # Asegurar que la función siempre retorne éxito si no hubo errores fatales
}

# Configuración de traps para manejo de señales
trap 'exit 1' SIGINT SIGTERM
trap 'cleanup' EXIT HUP PIPE

# Function to show license and disclaimer
show_license() {
    echo "$LICENSE_TEXT"
    exit "$EXIT_SUCCESS"
}

# Function to show process details
show_details() {
    echo "$DETAILS_TEXT"
    exit "$EXIT_SUCCESS"
}

# Function to clear screen using ANSI sequences
clear_screen() {
    echo -e "\033[2J\033[H"
}

# Function to clear command history
clear_history() {
    history -c
    history -w
}

# Function to check if input is a file
is_file() {
    [[ -f "$1" ]]
}

# Function to read words from file
read_words_from_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file" >&2
        exit "${EXIT_ERROR}"
    fi
    tr '\n' ' ' < "$file"
}

# Function to validate word count
validate_word_count() {
    local -a words=("$@")
    local count=${#words[@]}

    for valid_count in "${VALID_WORD_COUNTS[@]}"; do
        if [[ $count -eq $valid_count ]]; then
            return 0
        fi
    done

    echo "Invalid number of words: $count. Valid values are: ${VALID_WORD_COUNTS[*]}" >&2
    return 1
}

# Function to validate BIP39 words
validate_bip39_words() {
    local -a words=("$@")
    declare -A word_lookup invalid_words
    local word count=0

    # Crear hash table para búsqueda O(1)
    for word in "${WORDS[@]}"; do
        word_lookup["$word"]=1
    done

    # Verificar cada palabra y almacenar las inválidas
    for word in "${words[@]}"; do
        if [[ -z "${word_lookup[$word]:-}" ]]; then
            invalid_words["$word"]=1
            ((count++))
        fi
    done

    # Si hay palabras inválidas, mostrarlas todas
    if ((count > 0)); then
        echo "Invalid BIP39 words found:" >&2
        for word in "${!invalid_words[@]}"; do
            echo "  - $word" >&2
        done
        return 1
    fi

    return 0
}

validate_input() {
    local input="$1"

    # Verificar caracteres no permitidos
    if [[ "$input" =~ [^a-zA-Z0-9\ ] ]]; then
        log $LOG_ERROR "Invalid characters in input"
        echo "Error: Input contains invalid characters" >&2
        return 1
    fi

    # Verificar longitud máxima
    if [[ ${#input} -gt 1024 ]]; then
        log $LOG_ERROR "Input exceeds maximum length"
        echo "Error: Input too long" >&2
        return 1
    fi

    return 0
}

# Function to read password securely
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
        # Print prompts to stderr and ensure newlines
        printf "Enter password: " >&2
        read -s password
        printf "\n" >&2  # Explicit newline after password input

        printf "Confirm password: " >&2
        read -s password_confirm
        printf "\n\n" >&2  # Two explicit newlines after confirmation

        if [[ "$password" != "$password_confirm" ]]; then
            printf "Passwords do not match. Please try again.\n\n" >&2
            continue
        fi

        if [[ ${#password} -lt ${MIN_PASSWORD_LENGTH} ]]; then
            printf "Error: Password must be at least ${MIN_PASSWORD_LENGTH} characters long\n\n" >&2
            continue
        fi

        break
    done

    printf "%s" "$password"
}

# Function to generate seed from password
generate_seed_from_password() {
    local password="$1"
    local hash
    hash=$(printf "%s" "$password" | sha256sum | cut -d' ' -f1)
    printf "%d" "0x${hash:0:12}"
}

# Enhanced Fisher-Yates shuffle
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


# Generate nex seed from previous using sha-256
generate_next_seed() {
    local seed="$1"
    local hash
    hash=$(printf "%s" "$seed" | sha256sum | cut -d' ' -f1)
    printf "%d" "0x${hash:0:12}"
}

# Mix words function
mix_words() {
    local password="$1"
    local iterations="$2"
    declare -a mixed_words
    mixed_words=("${WORDS[@]}")
    local seed

    # Generate initial seed from password
    seed=$(generate_seed_from_password "$password")

    # Perform Fisher-Yates iterations
    for ((i = 1; i <= iterations; i++)); do
        # Do Fisher-Yates shuffle with current seed
        mapfile -t mixed_words < <(fisher_yates_shuffle "$seed" "${mixed_words[@]}")
        # Generate next seed from current one
        seed=$(generate_next_seed "$seed")
    done

    # Return the mixed words
    printf "%s\n" "${mixed_words[@]}"
}

# Function to create deterministic word pairs and transform input using them
create_pairs() {
    local password="$1"
    local iterations="$2"
    shift 2
    local -a input_words=("$@")

    if [[ "${DEBUG:-}" == "1" ]]; then
        echo "Processing words: ${input_words[*]}" >&2
        echo "Number of words to process: ${#input_words[@]}" >&2
    fi

    local -a mixed_words
    mapfile -t mixed_words < <(mix_words "$password" "$iterations")
    local -i half_size=$(( ${#mixed_words[@]} / 2 ))

    if (( ${#mixed_words[@]} % 2 != 0 )); then
        echo "Error: Internal error - invalid word list size" >&2
        exit "${EXIT_ERROR}"
    fi

    declare -A mapping

    for ((i = 0; i < half_size; i++)); do
        local word1="${mixed_words[i]}"
        local word2="${mixed_words[i + half_size]}"

        if [[ -z "$word1" || -z "$word2" ]]; then
            echo "Error: Empty word detected in mapping" >&2
            exit "${EXIT_ERROR}"
        fi

        if [[ "$word1" =~ [[:space:]] || "$word2" =~ [[:space:]] ]]; then
            echo "Error: Word contains whitespace" >&2
            exit "${EXIT_ERROR}"
        fi

        mapping["$word1"]="$word2"
        mapping["$word2"]="$word1"

        if [[ "${DEBUG:-}" == "1" ]]; then
            echo "Mapping: $word1 <-> $word2" >&2
        fi
    done

    local output=""
    for word in "${input_words[@]}"; do
        word=$(echo "$word" | tr -d '[:space:]')

        if [[ "${DEBUG:-}" == "1" ]]; then
            echo "Processing word: '$word'" >&2
        fi

        if [[ -n "${mapping[$word]+x}" ]]; then
            local mapped_word="${mapping[$word]}"

            if [[ "${DEBUG:-}" == "1" ]]; then
                echo "Input: $word -> Output: $mapped_word" >&2
            fi

            if [[ -z "$mapped_word" || "$mapped_word" =~ [[:space:]] ]]; then
                echo "Error: Invalid mapping result for '$word'" >&2
                exit "${EXIT_ERROR}"
            fi

            [[ -n "$output" ]] && output+=" "
            output+="$mapped_word"
        else
            echo "Error: '$word' is not in BIP39 wordlist" >&2
            exit "${EXIT_ERROR}"
        fi
    done

    if [[ "${DEBUG:-}" == "1" ]]; then
        echo "Final output: '$output'" >&2
    fi

    echo "$output"
}

# Validate output file
validate_output_file() {
    local file="$1"
    local dir
    dir=$(dirname "$file")

    # Validar que el directorio existe y tiene permisos de escritura
    [[ ! -d "$dir" ]] && {
        echo "Error: Directory does not exist: $dir" >&2
        exit "${EXIT_ERROR}"
    }

    [[ ! -w "$dir" ]] && {
        echo "Error: No write permission in directory: $dir" >&2
        exit "${EXIT_ERROR}"
    }

    # Verificar si el archivo existe
    if [[ -e "$file" ]]; then
        # Verificar permisos de escritura del archivo
        [[ ! -w "$file" ]] && {
            echo "Error: Cannot write to existing file: $file" >&2
            exit "${EXIT_ERROR}"
        }

        # Preguntar al usuario si desea sobrescribir
        while true; do
            read -p "File '$file' exists. Do you want to overwrite it? (y/n): " answer
            case $answer in
                [Yy]* )
                    return 0
                    ;;
                [Nn]* )
                    echo "Operation cancelled by user" >&2
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

# Cleanup function
cleanup() {
    local -r mask=$(umask)
    umask 077

    log $LOG_INFO "Starting cleanup process"

    # Limpiar variables sensibles
    if [[ -n "${PASSWORD:-}" ]]; then
        log $LOG_DEBUG "Cleaning sensitive data"
        PASSWORD="$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64)"
        PASSWORD=""
    fi

    # Restaurar umask
    umask "$mask"
    log $LOG_DEBUG "Restored umask to $mask"

    # Limpiar historial
    clear_history
    log $LOG_DEBUG "Command history cleared"

    # Limpiar descriptores de archivo
    exec 3>&- 2>/dev/null
    exec 2>&1
    log $LOG_DEBUG "File descriptors cleaned"

    log $LOG_INFO "Cleanup completed"
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
    -f OUTPUT_FILE   Save output to specified file (will append .txt if needed)
    -s, --silent     Silent mode (no prompts, for scripting)
    -d               Enable debug mode
    --license        Show license and disclaimer
    --details        Show detailed explanation of the cipher process
    -h, --help       Show this help message and exit

Examples:
    ${script_name} -f output.txt          # Save output to file
    ${script_name} --license              # View license and disclaimer
    ${script_name} --details              # Learn how the cipher works
    ${script_name} -s < input.txt         # Process input file in silent mode

$COMPATIBILITY_INFO

EOF

    # ASCII Art
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

# Enhanced main function
main() {
    log $LOG_INFO "Starting SCypher v${VERSION}"
    local output_file=""
    local silent_mode=0
    local password=""
    local input_words=()

    # Process command line arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -h|--help)
                log $LOG_INFO "Showing help message"
                show_usage
                ;;
            --license)
                log $LOG_INFO "Showing license information"
                show_license
                ;;
            --details)
                log $LOG_INFO "Showing process details"
                show_details
                ;;
            -f)
                [[ -z "$2" ]] && show_usage
                output_file="$2"
                log $LOG_INFO "Output file set to: $output_file"
                shift 2
                ;;
            -s|--silent)
                silent_mode=1
                log $LOG_INFO "Silent mode enabled"
                shift
                ;;
            -d)
                DEBUG=1
                log $LOG_INFO "Debug mode enabled"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    log $LOG_DEBUG "Command line arguments processed"

    # Process output file name
    if [[ -n "$output_file" ]]; then
        [[ "$output_file" != *"${EXTENSION}" ]] && output_file="${output_file}${EXTENSION}"
        log $LOG_DEBUG "Validating output file: $output_file"
        validate_output_file "$output_file"
    fi

    # Interactive input phase
    local input
    if [[ $silent_mode -eq 0 ]]; then
        echo ""
        echo -n "Enter seed phrase or input file: "
        read -r input
        echo  # Add newline after input

        if is_file "$input"; then
            log $LOG_INFO "Reading from file: $input"
            input=$(read_words_from_file "$input")
        else
            log $LOG_INFO "Reading input from user"
        fi
    else
        read -r input
        log $LOG_INFO "Reading input in silent mode"
    fi

    # Validate input format
    log $LOG_DEBUG "Validating input format"
    if ! validate_input "$input"; then
        log $LOG_ERROR "Input validation failed"
        exit "${EXIT_ERROR}"
    fi

    # Convert input to array
    read -ra input_words <<< "$input"

    # Validate word count
    log $LOG_DEBUG "Validating word count"
    if ! validate_word_count "${input_words[@]}"; then
        log $LOG_ERROR "Word count validation failed"
        exit "${EXIT_ERROR}"
    fi

    # Validate BIP39 words
    log $LOG_DEBUG "Validating BIP39 words"
    if ! validate_bip39_words "${input_words[@]}"; then
        log $LOG_ERROR "BIP39 word validation failed"
        exit "${EXIT_ERROR}"
    fi

    # Get password after successful validation
    if [[ $silent_mode -eq 0 ]]; then
        log $LOG_INFO "Reading password from user"
        password=$(read_secure_password)

        # Get number of iterations
        local iterations
        while true; do
            printf "\nEnter number of iterations (minimum 1): " >&2
            read iterations

            if [[ "$iterations" =~ ^[0-9]+$ ]] && [ "$iterations" -ge 1 ]; then
                log $LOG_INFO "Iterations set to: $iterations"
                break
            else
                log $LOG_WARN "Invalid iteration count provided"
                printf "Error: Please enter a positive number\n" >&2
            fi
        done
    else
        read -rs password
        read -r iterations
        log $LOG_INFO "Password and iterations read in silent mode"
    fi

    # Process words and get result
    log $LOG_INFO "Processing input with $iterations iteration(s)"
    local result
    result=$(create_pairs "$password" "$iterations" "${input_words[@]}")
    log $LOG_DEBUG "Word processing completed"

    # Output results
    echo ""
if [[ -n "$output_file" ]]; then
    log $LOG_INFO "Writing output to file: $output_file"
    if ! echo "$result" > "$output_file" 2>/dev/null; then
        log $LOG_ERROR "Failed to write to output file: $output_file"
        echo "Error: Failed to write to output file" >&2
        exit "${EXIT_ERROR}"
    fi

    if ! chmod "${PERMISSIONS}" "$output_file" 2>/dev/null; then
        log $LOG_ERROR "Failed to set permissions on output file"
        echo "Error: Failed to set file permissions" >&2
        exit "${EXIT_ERROR}"
    fi

    log $LOG_DEBUG "File permissions set to ${PERMISSIONS}"
    echo "$result"
    if [[ $silent_mode -eq 0 ]]; then
        echo ""
        echo "Output saved to ${output_file}"
        log $LOG_INFO "Results displayed and saved to file"
    fi
else
    echo ""
    echo "$result"
    log $LOG_INFO "Results displayed to stdout"
fi

    if [[ $silent_mode -eq 0 ]]; then
        echo ""
        echo ""
        read -p "Press enter to clear screen and continue..."
        clear_screen
    fi

    log $LOG_INFO "SCypher execution completed successfully"
}

# Enable strict mode
set -o errexit
set -o nounset
set -o pipefail

# Verificar compatibilidad del sistema
check_system_compatibility

# Start the script
main "$@"
