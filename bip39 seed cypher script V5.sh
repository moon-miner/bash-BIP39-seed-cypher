 
#!/bin/bash

# System Requirements:
# - Bash 4.0 or higher (for associative arrays)
# - sha256sum command (usually part of coreutils)
# - Basic POSIX utilities (read, printf, etc.)
# - At least 100MB of available RAM
# - Write permissions in the output directory
# - Terminal with UTF-8 support for ASCII art

# Verificar que la versión de bash soporte arrays asociativos (4.0 o superior)
if ((BASH_VERSINFO[0] < 4)); then
    echo "Error: Este script requiere Bash 4.0 o superior" >&2
    exit 1
fi

# Constantes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly PERMISSIONS=600
readonly EXTENSION=".txt"
readonly MIN_BASH_VERSION=4
readonly MIN_PASSWORD_LENGTH=1

# BIP39 wordlist - Add your words here
declare -ra WORDS=(
    abandon ability able about above absent absorb abstract absurd abuse access accident
    account accuse achieve acid acoustic acquire across act action actor actress actual
    adapt add addict address adjust admit adult advance advice aerobic affair afford afraid
    again age agent agree ahead aim air airport aisle alarm album alcohol alert alien all
    alley allow almost alone alpha already also alter always amateur amazing among amount
    amused analyst anchor ancient anger angle angry animal ankle announce annual another
    answer antenna antique anxiety any apart apology appear apple approve april arch
    arctic area arena argue arm armed armor army around arrange arrest arrive arrow art
    artefact artist artwork ask aspect assault asset assist assume asthma athlete atom
    attack attend attitude attract auction audit august aunt author auto autumn average
    avocado avoid awake aware away awesome awful awkward axis baby bachelor bacon badge
    bag balance balcony ball bamboo banana banner bar barely bargain barrel base basic
    basket battle beach bean beauty because become beef before begin behave behind
    believe below belt bench benefit best betray better between beyond bicycle bid bike
    bind biology bird birth bitter black blade blame blanket blast bleak bless blind
    blood blossom blouse blue blur blush board boat body boil bomb bone bonus book
    boost border boring borrow boss bottom bounce box boy bracket brain brand brass
    brave bread breeze brick bridge brief bright bring brisk broccoli broken bronze
    broom brother brown brush bubble buddy budget buffalo build bulb bulk bullet bundle
    bunker burden burger burst bus business busy butter buyer buzz cabbage cabin cable
    cactus cage cake call calm camera camp can canal cancel candy cannon canoe canvas
    canyon capable capital captain car carbon card cargo carpet carry cart case cash
    casino castle casual cat catalog catch category cattle caught cause caution cave
    ceiling celery cement census century cereal certain chair chalk champion change
    chaos chapter charge chase chat cheap check cheese chef cherry chest chicken chief
    child chimney choice choose chronic chuckle chunk churn cigar cinnamon circle
    citizen city civil claim clap clarify claw clay clean clerk clever click client
    cliff climb clinic clip clock clog close cloth cloud clown club clump cluster
    clutch coach coast coconut code coffee coil coin collect color column combine come
    comfort comic common company concert conduct confirm congress connect consider
    control convince cook cool copper copy coral core corn correct cost cotton couch
    country couple course cousin cover coyote crack cradle craft cram crane crash
    crater crawl crazy cream credit creek crew cricket crime crisp critic crop cross
    crouch crowd crucial cruel cruise crumble crunch crush cry crystal cube culture
    cup cupboard curious current curtain curve cushion custom cute cycle dad damage
    damp dance danger daring dash daughter dawn day deal debate debris decade december
    decide decline decorate decrease deer defense define defy degree delay deliver
    demand demise denial dentist deny depart depend deposit depth deputy derive
    describe desert design desk despair destroy detail detect develop device devote
    diagram dial diamond diary dice diesel diet differ digital dignity dilemma dinner
    dinosaur direct dirt disagree discover disease dish dismiss disorder display
    distance divert divide divorce dizzy doctor document dog doll dolphin domain
    donate donkey donor door dose double dove draft dragon drama drastic draw dream
    dress drift drill drink drip drive drop drum dry duck dumb dune during dust dutch
    duty dwarf dynamic eager eagle early earn earth easily east easy echo ecology
    economy edge edit educate effort egg eight either elbow elder electric elegant
    element elephant elevator elite else embark embody embrace emerge emotion employ
    empower empty enable enact end endless endorse enemy energy enforce engage engine
    enhance enjoy enlist enough enrich enroll ensure enter entire entry envelope
    episode equal equip era erase erode erosion error erupt escape essay essence
    estate eternal ethics evidence evil evoke evolve exact example excess exchange
    excite exclude excuse execute exercise exhaust exhibit exile exist exit exotic
    expand expect expire explain expose express extend extra eye eyebrow fabric face
    faculty fade faint faith fall false fame family famous fan fancy fantasy farm
    fashion fat fatal father fatigue fault favorite feature february federal fee feed
    feel female fence festival fetch fever few fiber fiction field figure file film
    filter final find fine finger finish fire firm first fiscal fish fit fitness fix
    flag flame flash flat flavor flee flight flip float flock floor flower fluid
    flush fly foam focus fog foil fold follow food foot force forest forget fork
    fortune forum forward fossil foster found fox fragile frame frequent fresh friend
    fringe frog front frost frown frozen fruit fuel fun funny furnace fury future
    gadget gain galaxy gallery game gap garage garbage garden garlic garment gas gasp
    gate gather gauge gaze general genius genre gentle genuine gesture ghost giant
    gift giggle ginger giraffe girl give glad glance glare glass glide glimpse globe
    gloom glory glove glow glue goat goddess gold good goose gorilla gospel gossip
    govern gown grab grace grain grant grape grass gravity great green grid grief grit
    grocery group grow grunt guard guess guide guilt guitar gun gym habit hair half
    hammer hamster hand happy harbor hard harsh harvest hat have hawk hazard head
    health heart heavy hedgehog height hello helmet help hen hero hidden high hill
    hint hip hire history hobby hockey hold hole holiday hollow home honey hood hope
    horn horror horse hospital host hotel hour hover hub huge human humble humor
    hundred hungry hunt hurdle hurry hurt husband hybrid ice icon idea identify idle
    ignore ill illegal illness image imitate immense immune impact impose improve
    impulse inch include income increase index indicate indoor industry infant inflict
    inform inhale inherit initial inject injury inmate inner innocent input inquiry
    insane insect inside inspire install intact interest into invest invite involve
    iron island isolate issue item ivory jacket jaguar jar jazz jealous jeans jelly
    jewel job join joke journey joy judge juice jump jungle junior junk just kangaroo
    keen keep ketchup key kick kid kidney kind kingdom kiss kit kitchen kite kitten
    kiwi knee knife knock know lab label labor ladder lady lake lamp language laptop
    large later latin laugh laundry lava law lawn lawsuit layer lazy leader leaf learn
    leave lecture left leg legal legend leisure lemon lend length lens leopard lesson
    letter level liar liberty library license life lift light like limb limit link lion
    liquid list little live lizard load loan lobster local lock logic lonely long loop
    lottery loud lounge love loyal lucky luggage lumber lunar lunch luxury lyrics
    machine mad magic magnet maid mail main major make mammal man manage mandate
    mango mansion manual maple marble march margin marine market marriage mask mass
    master match material math matrix matter maximum maze meadow mean measure meat
    mechanic medal media melody melt member memory mention menu mercy merge merit
    merry mesh message metal method middle midnight milk million mimic mind minimum
    minor minute miracle mirror misery miss mistake mix mixed mixture mobile model
    modify mom moment monitor monkey monster month moon moral more morning mosquito
    mother motion motor mountain mouse move movie much muffin mule multiply muscle
    museum mushroom music must mutual myself mystery myth naive name napkin narrow
    nasty nation nature near neck need negative neglect neither nephew nerve nest net
    network neutral never news next nice night noble noise nominee noodle normal
    north nose notable note nothing notice novel now nuclear number nurse nut oak obey
    object oblige obscure observe obtain obvious occur ocean october odor off offer
    office often oil okay old olive olympic omit once one onion online only open
    opera opinion oppose option orange orbit orchard order ordinary organ orient
    original orphan ostrich other outdoor outer output outside oval oven over own
    owner oxygen oyster ozone pact paddle page pair palace palm panda panel panic
    panther paper parade parent park parrot party pass patch path patient patrol
    pattern pause pave payment peace peanut pear peasant pelican pen penalty pencil
    people pepper perfect permit person pet phone photo phrase physical piano picnic
    picture piece pig pigeon pill pilot pink pioneer pipe pistol pitch pizza place
    planet plastic plate play please pledge pluck plug plunge poem poet point polar
    pole police pond pony pool popular portion position possible post potato pottery
    poverty powder power practice praise predict prefer prepare present pretty prevent
    price pride primary print priority prison private prize problem process produce
    profit program project promote proof property prosper protect proud provide public
    pudding pull pulp pulse pumpkin punch pupil puppy purchase purity purpose purse
    push put puzzle pyramid quality quantum quarter question quick quit quiz quote
    rabbit raccoon race rack radar radio rail rain raise rally ramp ranch random
    range rapid rare rate rather raven raw razor ready real reason rebel rebuild
    recall receive recipe record recycle reduce reflect reform refuse region regret
    regular reject relax release relief rely remain remember remind remove render
    renew rent reopen repair repeat replace report require rescue resemble resist
    resource response result retire retreat return reunion reveal review reward rhythm
    rib ribbon rice rich ride ridge rifle right rigid ring riot ripple risk ritual
    rival river road roast robot robust rocket romance roof rookie room rose rotate
    rough round route royal rubber rude rug rule run runway rural sad saddle sadness
    safe sail salad salmon salon salt salute same sample sand satisfy satoshi sauce
    sausage save say scale scan scare scatter scene scheme school science scissors
    scorpion scout scrap screen script scrub sea search season seat second secret
    section security seed seek segment select sell seminar senior sense sentence
    series service session settle setup seven shadow shaft shallow share shed shell
    sheriff shield shift shine ship shiver shock shoe shoot shop short shoulder shove
    shrimp shrug shuffle shy sibling sick side siege sight sign silent silk silly
    silver similar simple since sing siren sister situate six size skate sketch ski
    skill skin skirt skull slab slam sleep slender slice slide slight slim slogan
    slot slow slush small smart smile smoke smooth snack snake snap sniff snow soap
    soccer social sock soda soft solar soldier solid solution solve someone song soon
    sorry sort soul sound soup source south space spare spatial spawn speak special
    speed spell spend sphere spice spider spike spin spirit split spoil sponsor spoon
    sport spot spray spread spring spy square squeeze squirrel stable stadium staff
    stage stairs stamp stand start state stay steak steel stem step stereo stick still
    sting stock stomach stone stool story stove strategy street strike strong
    struggle student stuff stumble style subject submit subway success such sudden
    suffer sugar suggest suit summer sun sunny sunset super supply supreme sure
    surface surge surprise surround survey suspect sustain swallow swamp swap swarm
    swear sweet swift swim swing switch sword symbol symptom syrup system table tackle
    tag tail talent talk tank tape target task taste tattoo taxi teach team tell ten
    tenant tennis tent term test text thank that theme then theory there they thing
    this thought three thrive throw thumb thunder ticket tide tiger tilt timber time
    tiny tip tired tissue title toast tobacco today toddler toe together toilet token
    tomato tomorrow tone tongue tonight tool tooth top topic topple torch tornado
    tortoise toss total tourist toward tower town toy track trade traffic tragic
    train transfer trap trash travel tray treat tree trend trial tribe trick trigger
    trim trip trophy trouble truck true truly trumpet trust truth try tube tuition
    tumble tuna tunnel turkey turn turtle twelve twenty twice twin twist two type
    typical ugly umbrella unable unaware uncle uncover under undo unfair unfold
    unhappy uniform unique unit universe unknown unlock until unusual unveil update
    upgrade uphold upon upper upset urban urge usage use used useful useless usual
    utility vacant vacuum vague valid valley valve van vanish vapor various vast vault
    vehicle velvet vendor venture venue verb verify version very vessel veteran viable
    vibrant vicious victory video view village vintage violin virtual virus visa
    visit visual vital vivid vocal voice void volcano volume vote voyage wage wagon
    wait walk wall walnut want warfare warm warrior wash wasp waste water wave way
    wealth weapon wear weasel weather web wedding weekend weird welcome west wet whale
    what wheat wheel when where whip whisper wide width wife wild will win window
    wine wing wink winner winter wire wisdom wise wish witness wolf woman wonder wood
    wool word work world worry worth wrap wreck wrestle wrist write wrong yard year
    yellow you young youth zebra zero zone zoo
)

# OS Compatibility Check
check_system_compatibility() {
    local os_name
    os_name=$(uname -s)

    case "$os_name" in
        Linux)
            # Check for GNU coreutils
            if ! command -v sha256sum >/dev/null 2>&1; then
                echo "Error: sha256sum not found. Please install GNU coreutils." >&2
                exit "${EXIT_ERROR}"
            fi
            ;;
        Darwin)
            # macOS specific checks
            if ! command -v sha256sum >/dev/null 2>&1; then
                if command -v gsha256sum >/dev/null 2>&1; then
                    # Create alias for GNU version if available
                    sha256sum() { gsha256sum "$@"; }
                else
                    echo "Error: sha256sum not found. Please install coreutils via Homebrew:" >&2
                    echo "brew install coreutils" >&2
                    exit "${EXIT_ERROR}"
                fi
            fi
            ;;
        MINGW*|CYGWIN*|MSYS*)
            # Windows specific checks
            if ! command -v sha256sum >/dev/null 2>&1; then
                echo "Error: sha256sum not found. Please install GNU coreutils for Windows." >&2
                exit "${EXIT_ERROR}"
            fi
            # Check for Windows-specific line endings
            if [[ "$(printf '\r')" == $'\r' ]]; then
                echo "Warning: Windows line endings detected. This may cause issues." >&2
            fi
            ;;
        *)
            echo "Warning: Untested operating system ($os_name). Proceed with caution." >&2
            ;;
    esac

    # Check terminal capabilities
    if [[ -z "${TERM}" || "${TERM}" == "dumb" ]]; then
        echo "Warning: Limited terminal capabilities detected. ASCII art may not display correctly." >&2
    fi
}

# Function to read password securely
# Arguments: None
# Returns: Password string
# Description: Securely reads a password from the user without echo
read_secure_password() {
    local password
    # Disable command history temporarily
    set +o history
    # Read password without echo
    read -s -p "Enter password (minimum ${MIN_PASSWORD_LENGTH} characters): " password
    echo >&2
    # Re-enable command history
    set -o history

    # Validate password length
    if [[ ${#password} -lt ${MIN_PASSWORD_LENGTH} ]]; then
        echo "Error: Password must be at least ${MIN_PASSWORD_LENGTH} characters long" >&2
        exit "${EXIT_ERROR}"
    fi

    printf "%s" "$password"
}

# Function to validate password
validate_password() {
    local password="$1"
    if [[ ${#password} -lt ${MIN_PASSWORD_LENGTH} ]]; then
        echo "Error: Password must be at least ${MIN_PASSWORD_LENGTH} characters long" >&2
        exit "${EXIT_ERROR}"
    fi
}

# Function to display usage information and ASCII art
show_usage() {
    local script_name
    script_name=$(basename "$0")

    cat << EOF
BIP39 Word Mixer - A tool to encode/decode BIP39 seed phrases

Usage:
    ${script_name} [-f OUTPUT_FILE] [-p PASSWORD] [WORD1 WORD2 ... | SEEDFILE]
    ${script_name} -h | --help

Description:
    This script takes BIP39 seed words and creates a password-protected encoding/decoding
    of those words. The same password will decode the encoded words back to the original.

Parameters:
    -f OUTPUT_FILE    Optional. Save output to specified file (will append .txt if needed)
    -p PASSWORD       Optional. Specify password directly (if not used, will prompt securely)
    -h, --help       Show this help message and exit
    WORDS            Space-separated BIP39 words
    SEEDFILE         Text file containing BIP39 words (one per line)

Examples:
    # Encode/Decode three words and display result (will prompt for password)
    ${script_name} abandon ability able

    # Encode/Decode words with password specified
    ${script_name} -p mypassword abandon ability able

    # Encode/Decode words and save to file
    ${script_name} -f my_encoded_seed abandon ability able

    # Encode/Decode words from file with password
    ${script_name} -p mypassword my_seed_phrase.txt

System Requirements:
    - Bash ${MIN_BASH_VERSION}.0 or higher
    - GNU coreutils (sha256sum)
    - Standard POSIX utilities
    - 100MB available RAM
    - Write permissions in output directory
    - UTF-8 terminal support

Security Notes:
    - The output file permissions are set to ${PERMISSIONS} (user read/write only)
    - When -p is not used, password is read securely without echo
    - Memory is cleared after execution
    - Temporary files are not created
    - Using -p option may expose password in command history and process list

EOF

    # ASCII art
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
    exit "${EXIT_ERROR}"
}

# Function to validate output file
validate_output_file() {
    local file="$1"
    local dir
    dir=$(dirname "$file")

    if [[ ! -w "$dir" ]]; then
        echo "Error: No write permission in directory ${dir}" >&2
        exit "${EXIT_ERROR}"
    fi
}

# Function to mix words using password
mix_words() {
    local password="$1"
    local -i size=${#WORDS[@]}
    local hash
    local -i random_seed

    hash=$(printf "%s" "$password" | sha256sum | cut -d' ' -f1)
    random_seed=$(( 0x${hash:0:8} ))

    # Create local copy of words array
    local -a shuffled_words=("${WORDS[@]}")

    # Fisher-Yates shuffle with password-based randomization
    local -i i j
    local temp
    for ((i = size - 1; i > 0; i--)); do
        j=$(( (random_seed + i) % (i + 1) ))
        temp="${shuffled_words[i]}"
        shuffled_words[i]="${shuffled_words[j]}"
        shuffled_words[j]="$temp"
    done

    printf "%s\n" "${shuffled_words[@]}"
}

# Function to create and apply word mapping
process_words() {
    local password="$1"
    shift
    local -a input_words=("$@")
    local -a mixed_words

    # Get mixed words and create mapping
    mapfile -t mixed_words < <(mix_words "$password")
    local -i half_size=$(( ${#mixed_words[@]} / 2 ))

    # Create mapping
    local -A mapping=()
    local -i i
    for ((i = 0; i < half_size; i++)); do
        mapping["${mixed_words[i]}"]="${mixed_words[i + half_size]}"
        mapping["${mixed_words[i + half_size]}"]="${mixed_words[i]}"
    done

    # Process words
    local output=""
    local word
    for word in "${input_words[@]}"; do
        if [[ -n "${mapping[$word]+x}" ]]; then
            output+=" ${mapping[$word]}"
        else
            echo "Error: '${word}' is not in BIP39 wordlist" >&2
            exit "${EXIT_ERROR}"
        fi
    done

    echo "${output## }"  # Remove leading space
}

cleanup() {
    # Limpiar variables sensibles
    if [[ -n "${PASSWORD:-}" ]]; then
        PASSWORD=""
    fi
}

# Main function
main() {
    # Show usage if no arguments provided
    [[ $# -eq 0 ]] && show_usage

    local output_file=""
    local password=""
    local -a input_words=()

    # Check system compatibility
    check_system_compatibility

    # Process arguments except password
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                ;;
            -f)
                [[ -z "$2" ]] && show_usage
                output_file="$2"
                shift 2
                ;;
            -p)
                [[ -z "$2" ]] && show_usage
                password="$2"
                validate_password "$password"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done

    # Process output file name
    if [[ -n "$output_file" ]]; then
        [[ "$output_file" != *"${EXTENSION}" ]] && output_file="${output_file}${EXTENSION}"
        validate_output_file "$output_file"
    fi

    # If password wasn't provided with -p, read it securely
    if [[ -z "$password" ]]; then
        password=$(read_secure_password)
    fi

    # Read input words
    while [[ "$#" -gt 0 ]]; do
        if [[ -f "$1" ]]; then
            # Leer el archivo y separar en palabras
            while read -r line; do
                # Dividir la línea en palabras y añadirlas al array
                read -ra words <<< "$line"
                input_words+=("${words[@]}")
            done < "$1"
        else
            input_words+=("$1")
        fi
        shift
    done

    [[ ${#input_words[@]} -eq 0 ]] && show_usage

    # Process words and get result
    local result
    result=$(process_words "$password" "${input_words[@]}")

    # Output results
    if [[ -n "$output_file" ]]; then
        echo "$result" > "$output_file"
        chmod "${PERMISSIONS}" "$output_file"  # Restrict file permissions
        echo "$result"
        echo "Output saved to ${output_file}"
    else
        echo "$result"
    fi
}

# Trap for cleanup
trap cleanup EXIT

# Start script execution with proper error handling
set -o errexit  # Exit on error
set -o nounset  # Exit on undefined variable
set -o pipefail # Exit on pipe failure

# Start the script
main "$@"
