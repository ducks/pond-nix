#!/usr/bin/env bash
set -e

# Name.com API credentials (pass as env vars or set here)
: ${NAMECOM_USERNAME:?"Set NAMECOM_USERNAME environment variable"}
: ${NAMECOM_TOKEN:?"Set NAMECOM_TOKEN environment variable"}

# New server IP
NEW_IP="199.68.196.244"

# Domains to update
declare -A RECORDS=(
    ["jakegoldsborough.com"]="code,ci,stats,scrob,ui.scrob"
    ["date-ver.com"]="stats"
    ["gnarlyvoid.com"]="stats"
)

API_BASE="https://api.name.com/v4"
AUTH="${NAMECOM_USERNAME}:${NAMECOM_TOKEN}"

echo "=== Updating DNS records to point to $NEW_IP ==="
echo ""

# Function to get record ID
get_record_id() {
    local domain="$1"
    local subdomain="$2"

    curl -s -u "$AUTH" \
        "${API_BASE}/domains/${domain}/records" \
        | jq -r ".records[] | select(.fqdn == \"${subdomain}.${domain}.\") | .id"
}

# Function to update A record
update_record() {
    local domain="$1"
    local subdomain="$2"
    local record_id="$3"

    echo "Updating ${subdomain}.${domain} -> ${NEW_IP}"

    curl -s -u "$AUTH" \
        -X PUT \
        -H "Content-Type: application/json" \
        -d "{
            \"host\": \"${subdomain}\",
            \"type\": \"A\",
            \"answer\": \"${NEW_IP}\",
            \"ttl\": 300
        }" \
        "${API_BASE}/domains/${domain}/records/${record_id}" > /dev/null

    if [ $? -eq 0 ]; then
        echo "  ✓ Updated"
    else
        echo "  ✗ Failed"
    fi
}

# Function to create A record if it doesn't exist
create_record() {
    local domain="$1"
    local subdomain="$2"

    echo "Creating ${subdomain}.${domain} -> ${NEW_IP}"

    curl -s -u "$AUTH" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{
            \"host\": \"${subdomain}\",
            \"type\": \"A\",
            \"answer\": \"${NEW_IP}\",
            \"ttl\": 300
        }" \
        "${API_BASE}/domains/${domain}/records" > /dev/null

    if [ $? -eq 0 ]; then
        echo "  ✓ Created"
    else
        echo "  ✗ Failed"
    fi
}

# Process each domain
for domain in "${!RECORDS[@]}"; do
    echo "Processing ${domain}..."
    subdomains="${RECORDS[$domain]}"

    IFS=',' read -ra SUBS <<< "$subdomains"
    for subdomain in "${SUBS[@]}"; do
        record_id=$(get_record_id "$domain" "$subdomain")

        if [ -n "$record_id" ]; then
            update_record "$domain" "$subdomain" "$record_id"
        else
            create_record "$domain" "$subdomain"
        fi
    done

    echo ""
done

echo "=== DNS update complete! ==="
echo ""
echo "Records updated:"
echo "  - code.jakegoldsborough.com"
echo "  - ci.jakegoldsborough.com"
echo "  - stats.jakegoldsborough.com"
echo "  - scrob.jakegoldsborough.com"
echo "  - ui.scrob.jakegoldsborough.com"
echo "  - stats.date-ver.com"
echo "  - stats.gnarlyvoid.com"
echo ""
echo "DNS propagation may take a few minutes."
echo "Test with: dig code.jakegoldsborough.com +short"
