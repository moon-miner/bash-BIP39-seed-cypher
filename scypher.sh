#!/bin/bash

# System Requirements:
# - Bash 4.0 or higher (for associative arrays)
# - sha256sum command (usually part of coreutils)
# - Basic POSIX utilities (read, printf, etc.)
# - At least 100MB of available RAM
# - Write permissions in the output directory
# - Terminal with UTF-8 support for ASCII art

# Check for Bash version support (4.0 or higher required for associative arrays)
if ((BASH_VERSINFO[0] < 4)); then
    echo "Error: This script requires Bash 4.0 or higher" >&2
    exit 1
fi

# Constants
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly PERMISSIONS=600
readonly EXTENSION=".txt"
readonly MIN_BASH_VERSION=4
readonly MIN_PASSWORD_LENGTH=1
readonly VALID_WORD_COUNTS=(12 15 18 21 24)

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

# Clear screen using ANSI sequences
clear_screen() {
    echo -e "\033[2J\033[H"
}

# Clear command history
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
    local -a invalid_words=()
    local word

    for word in "${words[@]}"; do
        if [[ ! " ${WORDS[*]} " =~ " ${word} " ]]; then
            invalid_words+=("$word")
        fi
    done

    if [[ ${#invalid_words[@]} -gt 0 ]]; then
        echo "Invalid BIP39 words found: ${invalid_words[*]}" >&2
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
    printf "%d" "0x${hash:0:8}"
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
        seed=$(( (seed * 1103515245 + 12345) % 2147483648 ))

        if [[ $i -lt $size && $j -lt $size && -n "${arr[i]}" && -n "${arr[j]}" ]]; then
            temp="${arr[i]}"
            arr[i]="${arr[j]}"
            arr[j]="$temp"
        fi
    done

    printf "%s\n" "${arr[@]}"
}

# Transform segments function
transform_segments() {
    local -i seed="$1"
    local -a arr=("${@:2}")
    local -i size=${#arr[@]}
    local -i segment_size=$(( size / 4 ))
    local -i offset
    local temp

    for ((segment = 0; segment < 4; segment++)); do
        offset=$((segment * segment_size))

        for ((i = 0; i < segment_size / 2; i++)); do
            local pos1=$((offset + i))
            local pos2=$((offset + segment_size - 1 - i))

            if [[ $pos1 -lt $size && $pos2 -lt $size && -n "${arr[pos1]}" && -n "${arr[pos2]}" ]]; then
                seed=$(( (seed * 1103515245 + 12345) % 2147483648 ))
                if (( seed % 2 )); then
                    temp="${arr[pos1]}"
                    arr[pos1]="${arr[pos2]}"
                    arr[pos2]="$temp"
                fi
            fi
        done
    done

    printf "%s\n" "${arr[@]}"
}

# Perfect Shuffle function
perfect_shuffle() {
    local password="$1"
    local -a mixed_words=("${WORDS[@]}")
    local -i seed1 seed2

    seed1=$(generate_seed_from_password "$password")
    mapfile -t mixed_words < <(fisher_yates_shuffle "$seed1" "${mixed_words[@]}")

    if [[ ${#mixed_words[@]} -ne ${#WORDS[@]} ]]; then
        echo "Error: Word count mismatch after shuffle" >&2
        exit "${EXIT_ERROR}"
    fi

    seed2=$(( (seed1 * 1103515245 + 12345) % 2147483648 ))
    mapfile -t mixed_words < <(transform_segments "$seed2" "${mixed_words[@]}")

    seed2=$(( (seed2 * 1103515245 + 12345) % 2147483648 ))
    mapfile -t mixed_words < <(fisher_yates_shuffle "$seed2" "${mixed_words[@]}")

    if [[ ${#mixed_words[@]} -ne ${#WORDS[@]} ]]; then
        echo "Error: Final word count mismatch" >&2
        exit "${EXIT_ERROR}"
    fi

    printf "%s\n" "${mixed_words[@]}"
}

# Mix words function
mix_words() {
    local password="$1"
    perfect_shuffle "$password"
}

# Process words function
process_words() {
    local password="$1"
    shift
    local -a input_words=("$@")

    if [[ "${DEBUG:-}" == "1" ]]; then
        echo "Processing words: ${input_words[*]}" >&2
        echo "Number of words to process: ${#input_words[@]}" >&2
    fi

    local -a mixed_words
    mapfile -t mixed_words < <(mix_words "$password")
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

# Show usage information and ASCII art
show_usage() {
    local script_name
    script_name=$(basename "$0")

    cat << EOF
Enhanced BIP39 seed cipher - A tool to encode/decode BIP39 seed phrases
Using Perfect Shuffle algorithm for optimal distribution

Usage:
    ${script_name} [-f OUTPUT_FILE] [-s] [-d] [-h]

Options:
    -f OUTPUT_FILE    Save output to specified file (will append .txt if needed)
    -s, --silent     Silent mode (no prompts, for scripting)
    -d               Enable debug mode
    -h, --help       Show this help message and exit

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
    exit "${EXIT_ERROR}"
}

# Validate output file
validate_output_file() {
    local file="$1"
    local dir
    dir=$(dirname "$file")

    if [[ ! -w "$dir" ]]; then
        echo "Error: No write permission in directory ${dir}" >&2
        exit "${EXIT_ERROR}"
    fi
}

# Cleanup function
cleanup() {
    if [[ -n "${PASSWORD:-}" ]]; then
        PASSWORD=""
    fi
    if [[ -n "${DEBUG:-}" ]]; then
        unset DEBUG
    fi
    clear_history
}

# Main function
main() {
    local output_file=""
    local silent_mode=0
    local password=""
    local input_words=()

    # Process only flags
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
            -s|--silent)
                silent_mode=1
                shift
                ;;
            -d)
                DEBUG=1
                shift
                ;;
            *)
                shift  # Ignore other arguments
                ;;
        esac
    done

    # Process output file name
    if [[ -n "$output_file" ]]; then
        [[ "$output_file" != *"${EXTENSION}" ]] && output_file="${output_file}${EXTENSION}"
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
            input=$(read_words_from_file "$input")
        fi
    else
        read -r input
    fi

    # Convert input to array
    read -ra input_words <<< "$input"

    # Validate input
    if ! validate_word_count "${input_words[@]}"; then
        exit "${EXIT_ERROR}"
    fi

    if ! validate_bip39_words "${input_words[@]}"; then
        exit "${EXIT_ERROR}"
    fi

    # Get password after successful validation
    if [[ $silent_mode -eq 0 ]]; then
        password=$(read_secure_password)
    else
        read -rs password
    fi

    # Process words and get result
    local result
    result=$(process_words "$password" "${input_words[@]}")

    # Output results
    echo ""
    if [[ -n "$output_file" ]]; then
        echo "$result" > "$output_file"
        chmod "${PERMISSIONS}" "$output_file"
        echo "$result"
        if [[ $silent_mode -eq 0 ]]; then
        echo ""
            echo "Output saved to ${output_file}"
        fi
    else
        echo ""
        echo "$result"
    fi

    if [[ $silent_mode -eq 0 ]]; then
    echo ""
    echo ""
        read -p "Press enter to clear screen and continue..."
        clear_screen
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Enable strict mode
set -o errexit
set -o nounset
set -o pipefail

# Start the script
main "$@"
