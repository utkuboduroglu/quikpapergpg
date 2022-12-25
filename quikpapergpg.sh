#!/usr/bin/bash

# default options for processing requests
REDUNDANCY=M
RESOLUTION=20

# usage prompt, displayed whenever an incorrect state is reached or the -h flag is requested
usage() {
    echo -ne "Usage: $0 -k <user secret key> [-h -l <redundancy> -s <qr code resolution>]\n" \
             "\t-h: display this help page.\n" \
             "\t-k <secret>: the user's secret key.\n" \
             "\t-l <redundancy>: set the QR code redundancy level, which helps data recovery.\n" \
             "\t-s <resolution>: set the pixel resolution for the QR code.\n" 
}

# we configure the required(!) values for exporting our secret key
# optional argument processing done through https://stackoverflow.com/a/38697692/4287715
while getopts "k:lsh" opt; do
    case "${opt}" in
        k)
            USER_ID=${OPTARG}
            ;;
        l)
            # Check next positional parameter
            eval nextopt=\${$OPTIND}
            # existing or starting with dash?
            if [[ -n $nextopt && $nextopt != -* ]] ; then
              OPTIND=$((OPTIND + 1))
              REDUNDANCY=$nextopt
            else
              REDUNDANCY=M
            fi
            ;;
        s)
            # Check next positional parameter
            eval nextopt=\${$OPTIND}
            # existing or starting with dash?
            if [[ -n $nextopt && $nextopt != -* ]] ; then
              OPTIND=$((OPTIND + 1))
              RESOLUTION=$nextopt
            else
              RESOLUTION=20
            fi
            ;;
        h | *)
            usage
            exit 0
            ;;
    esac
done

# we display the usage prompt if the user secret is not set
if [ -z ${USER_ID+x} ]; then
    usage 1>&2
    exit 1
fi

# we first store our secret key in memory
# ( we have to store the data in a temp file as there may be null-bytes )
TEMPFILE=$(mktemp)
gpg --export-secret-key $USER_ID > $TEMPFILE

if [ -s $TEMPFILE ]; then
    # we first export to paperkey directly
    paperkey < $TEMPFILE
    # next, we pass through paperkey and go through qrencode
    paperkey --output-type raw < $TEMPFILE \
        | qrencode --8bit -s $RESOLUTION -l $REDUNDANCY -o-
fi

# we run cleanup on the temporary file
rm -f $TEMPFILE
