
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
    --exclude "./bitrix/modules/fileman/install/components/bitrix" \
    --exclude "./bitrix/modules/highloadblock" \
    --exclude "./bitrix/modules/bitrix.sitecorporate" \
    --exclude "./bitrix/modules/perfmon" \
    --exclude "./bitrix/modules/bitrixcloud" \
    --exclude "./bitrix/modules/translate" \
    --exclude "./bitrix/wizards/bitrix/demo"

echo "Create start archive..."
rm start_encode_php5.tar.gz
tar -zcf ../start.tar.gz ./

echo "Create core archive..."
#TODO!!! поудалять еще какие нибуть ненужные в минимальной сборке модули
rm -R bitrix/modules/compression/
rm -R bitrix/modules/landing/
tar -zcf ../core.tar.gz ./
