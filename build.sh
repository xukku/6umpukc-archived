
echo "Cleanup..."

if [ -f small.tar.gz ]
then
    rm small.tar.gz
fi
if [ -d tmp ]
then
    rm -R tmp
    mkdir tmp
    cd tmp
fi

echo "Loading..."
curl -OL http://www.1c-bitrix.ru/download/first_site_encode_php5.tar.gz

echo "Unpacking..."
tar -xzf first_site_encode_php5.tar.gz \
    --exclude "./bitrix/modules/iblock"

# small
echo "Create small archive..."
rm first_site_encode_php5.tar.gz
tar -zcf ../small.tar.gz ./
