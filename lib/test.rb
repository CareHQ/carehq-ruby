
require './carehq'


client = APIClient.new('1', '2', '3')

r = client.request('GET', '/test', {'id' => nil, 'foo' => ['bar', 'zee']})

