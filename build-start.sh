
echo "Cleanup..."
if [ -f start.tar.gz ]
then
    rm start.tar.gz
fi
if [ -d tmp ]
then
    rm -R tmp
fi

mkdir tmp
cd tmp

echo "Loading..."
curl -OL https://www.1c-bitrix.ru/download/start_encode_php5.tar.gz

echo "Unpacking..."
tar -xzf start_encode_php5.tar.gz \
    --exclude "./bitrix/modules/iblock/install/components/bitrix" \
    --exclude "./bitrix/modules/highloadblock" \
    --exclude "./bitrix/modules/seo" \
    --exclude "./bitrix/modules/bitrix.sitecorporate" \
    --exclude "./bitrix/modules/perfmon" \
    --exclude "./bitrix/modules/bitrixcloud" \
    --exclude "./bitrix/modules/search" \
    --exclude "./bitrix/modules/translate" \
    --exclude "./bitrix/wizards/bitrix/demo"

# start
echo "Create start archive..."
rm start_encode_php5.tar.gz
tar -zcf ../start.tar.gz ./
