# CareHQ Ruby API client

CareHQ API Client for Ruby.


## Install

```
gem install carehq
```


## Requirements

- Ruby 2.3.0 or higher
- httparty


# Usage

```Ruby

require 'carehq'

api_client = APIClient.new(
    'MY_ACCOUNT_ID',
    'MY_API_KEY',
    'MY_API_SECRET'
)

users = api_client.request(
    'get',
    'users',
    params: {
        'attributes' => [
            'first_name',
            'last_name'
        ],
        'filters-q' => 'ant'
    }
)

```
