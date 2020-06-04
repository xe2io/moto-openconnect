#!/bin/bash

URL_PORTAL='https://access.motorolasolutions.com'
# Allow overriding portal gateway
if [ ! -z $VPNGW ]; then
    URL_PORTAL="https://${VPNGW}-access.motorolasolutions.com"
fi

URL_LOGIN="${URL_PORTAL}/dana-na/auth/url_default/login.cgi"

# These are dependent on what user has configured in Okta
# TODO: this keeps changing; now u2f disappeared
# Okta Actions; 1 = U2F (FIDO 1.0); 2 = Okta Verify (code; not supported); 3 = Okta Push
okta_action='2'

realm='OKTA+Login'

# TODO: Useragent?
# Script requires: jq curl awk openconnect
DEPENDENCIES="jq curl awk openconnect"
for d in $DEPENDENCIES; do
    which $d > /dev/null
    if [[ 0 -ne $? ]]; then
        echo "This utility requires '$d'."
        exit 1
    fi
done

### PHASE 1: Authenticate using DS Domain credentials

# Prompt for credentials
echo -n "Username: "
read user
echo -n "Password: "
stty -echo
read pass
stty echo

url_pass=$(echo -n $pass | jq -s -R -r @uri)

unset pass

data="tz_offset=0&username=${user}&password=${url_pass}&realm=${realm}&btnSubmit=Sign+In"
unset url_pass

# Capture response headers for defender_id
headers_file=$(mktemp)

echo -e "\n\nLogging in to Access Motorola Portal..."
p1_url=$(curl -s ${URL_LOGIN} --data "${data}" -H "Referer: ${URL_PORTAL}/dana-na/auth/url_default/welcome.cgi" -H 'Content-Type: application/x-www-form-urlencoded' -o /dev/null -w '%{redirect_url}' -D $headers_file)

unset data

# Check the 302 redirect URL
# Failure: https://access.motorolasolutions.com/dana-na/auth/url_default/welcome.cgi?p=failed
# Success: https://access.motorolasolutions.com/dana-na/auth/url_default/welcome.cgi?p=defender
if [[ "$p1_url" == *failed ]]; then
    echo "Failed login.  Please check credentials."
    exit 1
fi

# Grab the defender state ID (set in cookie) to pass to phase 2
defender_id=$(grep -Po '(?<=Set-Cookie: id=)(state_[0-9a-f]{32})' $headers_file)
rm $headers_file

if [[ -z "$defender_id" ]]; then
    echo "ERROR: Failed to retrieve defender state ID."
    exit 1
fi

### PHASE 2: Choose Okta Push (2) for 2FA
data="username=${user}&key=${defender_id}&password=${okta_action}&btnAction=++Sign+In++"

# -H "Referer: $p1_url"

echo "Requesting Okta Push.  Please acknowledge 2FA to continue."
cookie_file=$(mktemp)

curl -L -s ${URL_LOGIN} -o /dev/null --data "${data}" -c $cookie_file
unset data

vpn_cookie=$(awk 'match($0, /DSID.*[a-f0-9]+/) {printf "%s=%s", $(NF-1), $NF}' $cookie_file)
rm $cookie_file

### Get VPN cookie (DSID=____) from cookie, pass to openconnect
if [[ -z "$vpn_cookie" ]]; then
    echo "Failed to get VPN cookie.  Please try again."
    exit 1
fi

echo "VPN Cookie: $vpn_cookie"
echo -e "Launching OpenConnect with VPN Cookie..."
#openconnect --juniper --timestamp -C "$vpn_cookie" $URL_PORTAL 
echo "Disabling ESP since rekey issue (after ~1hr) is still unresolved."
openconnect --juniper --timestamp --no-dtls -C "$vpn_cookie" $URL_PORTAL 
