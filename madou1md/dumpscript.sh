set -o errexit

make libmd && make madou1md_scriptdmp
./madou1md_scriptdmp madou1.md script/
