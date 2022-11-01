---
NECESSARY ENVS

ENV['DEVISE_SECRET_KEY']
---

NECESSARY CONFIGS

c.errors_email

---

#Commercity

## STYLE GUIDE (ISH)

#### Model Order

Follow the below (from: https://github.com/bbatsov/rails-style-guide#macro-style-methods)

```Ruby
class User < ActiveRecord::Base

    # keep the default scope first (if any)
    default_scope { where(active: true) }

    # constants come up next
    COLORS = %w(red green blue)

    # SCOPES
    scope :published, (-> { where(published: true) })

    # afterwards we put attr related macros
    attr_accessor :formatted_date_of_birth

    attr_accessible :login, :first_name, :last_name, :email, :password

    # Rails4+ enums after attr macros, prefer the hash syntax
    enum gender: [:female, :male]

    # followed by association macros
    belongs_to :country

    has_many :authentications, dependent: :destroy

    accepts_nested_attributes_for :menu_items

    # and validation macros
    validates :email, presence: true
    validates :username, presence: true
    validates :username, uniqueness: { case_sensitive: false }
    validates :username, format: { with: /\A[A-Za-z][A-Za-z0-9._-]{2,19}\z/ }
    validates :password, format: { with: /\A\S{8,128}\z/, allow_nil: true }

    # next we have callbacks
    before_save :cook
    before_save :update_username_lower

    # other macros (like devise's) should be placed after the callbacks

    ...
end
```

## CHECKLIST OF NECESSARY THINGS TO DEPLOY

### Periodic Task Configuration

The periodic task can be run with `rails c:periodic_task`. By default, the task
list is empty, but the task will not error.

To add or remove tasks, go to `$CLIENT_APP/config/initializers/commercity.rb`
and set `config.periodic_task_list = [ # tasks_go_here # ]`. A list of tasks and
their explanations can be found in `$COMMERCITY/lib/c.rb`.

### Setting up eBay

First set up the eBay environment vars on Heroku: EBAY_APP_ID, EBAY_AUTH_TOKEN,
EBAY_CERT_ID, EBAY_DEV_ID, EBAY_ENVIRONMENT, EBAY_RU_NAME.

All can be copied from already deployed site except for EBAY_AUTH_TOKEN which
has to be generated using client credentials.

Secondly, run `rake c:ebay:deploy` somehow to seed all delivery services and
to import all eBay categories and to then create tree hierarchy.

### Action Cable

You will need **redis** running in order to recieve action cable updates, this is due to a bug in action cable preventing it from using the default mode of _async_. To use reddis:

#### Install Redis:

1. brew install redis
2. brew services start redis

#### Configure Action Cable

In your `config/cable.yml` file paste the following:

```
development:
  adapter: redis
  url: redis://localhost:6379/1

test:
  adapter: redis
  url: redis://localhost:6379/1

production:
  adapter: redis
  url: <%= ENV['REDIS_URL'] %>
```

#### On Heroku

1. Install the redis addon
2. profit

### React

/You'll need to be in the current components directory to use the following commands./

##### Prerequisites

Node needs to be installed on your machine.
If you have Homebrew installed just enter `brew install yarn`, then `brew upgrade yarn`.

##### Setup

All you need to do is download the node packages with `yarn install`.

##### Development

Use `yarn run development` to have the bundled js file rebuilt on any change in the source.

##### Production

`yarn run build` will do a one off build of your bundled js.

##### Overview

The code lives in the /./src/ directory.

When `yarn run build` is run everything in src will be bundled together into one file called /components.js/, found in the ./javascripts/components directory.

Generic components/utils live in the javscript_lib and app specific components in the components directory.
You'll need to add app specific components to the switch statement in app_components.js.
App specific code should not be placed into the javascript_lib but instead passed down into it using props.

Components can be used by calling the /react_component/ partial with a componentId, componentType and optional params.

e.g. `=render 'react_component', componentId: 'background-jobs-display', componentType: 'BackgroundJobsDisplay' params: {name: "Commercity"}`

componentId - will be used as the id on the components parent div.
componentType - must match the name of the component in the generic/app_components switch statements.
params - are the parameters you want to pass to the component

##### Commands

`yarn install` - installs all packages declared in the package.json.

`yarn add #package-name# (or) --save-dev` - add node package for production or development.

`yarn remove #package-name# --save (or) --save-dev` - remove node package for production or development.

`yarn run development` - will watch the current directory and rebundle on change.

`yarn run build` - creates the bundled js file.

## Complex Concepts (maybe)

### Background jobs auto management

Simply surround your code the BackgroundJob#perform method to automatically set
the correct status and last ran time.

```Ruby
block_result = C::BackgroundJob.perform('Name of Job', other_attr: 123) do |job|
  # Do something here
  # Job is available as the block argument
  job.update(job_attr: 123)
end
```

If `self_destruct: true` is given as a keyword argument, the job will be
destroyed once complete.

```Ruby
C::BackgroundJob.perform('Name of Job', self_destruct: true) do |job|
  # job is available
end
# job is now destroyed
```

If the block raises any error, the job will fail. The error should be logged to
ERROR.

```Ruby
C::BackgroundJob.perform('Name of Job', self_destruct: true) do |job|
  raise SomeKindOfError
end
# job is now failed and not destroyed
```

## Spreadsheet export

The following classes are namespaced within `C::SpreadsheetExport`:

### Exporter

The exporter can be initalised with the following signature:

```Ruby
workbook = C::SpreadsheetExport.new(filename, rows, properties = {})
```

Where:

- `filename` is the name of the file to write to. This must be accessible and
  writeable.

- `rows` is a two-dimensional array of values to place into the spreadsheet,
  beginning from cell A1. Date and Money objects have their formatting set in
  the spreadsheet properly.

- `properties` can contain metadata for the workbook itself. Three possible
  options (and their defaults) are:

  - `title`: 'Commercity Export'
  - `author`: The store name as defined in `commercity.rb`
  - `comments`: A brief comment with the current version of Commercity.

  See http://cxn03651.github.io/write_xlsx/workbook.html#set_properties for more
  information on the possible properties.

To actually write out to the file, call `export` on the object:

```Ruby
workbook.export
```

### Orders

A class that marshalls and converts orders as necessary to rows suitable for the
Exporter class.

#### Field Config

See below for examples and explanations for each option in the field config.

```Ruby
FIELD_CONFIG = {
  # For invoices. Defines the fields to be shown in the summary row. No label
  # will be shown and they must not outnumber the item fields.
  summary_fields: %w[total_price],

  # For invoices and item lists. Defines the fields to be shown for the order
  # items. Header labels for each field will be placed above the item list.
  # (Invoices note: put summarised fields at the end in the same order as above)
  item_fields: %w[name created_by quantity price],

  # For item lists.
  # Defines the field by which to group the items. Must obviously be a
  # reasonable identifier.
  group_field: :product_id,

  # For item lists.
  # Defines the item list fields that should not be summed. Uses the value of
  # the first item instead.
  static_fields: %w[name created_at]
}.freeze
```

#### Invoices

Invoices show an extremely simple list of items with a summary field at the
bottom. Ensure that both `summary_fields` and `item_fields` are set in the field
config.

Invoices can be created as following:

```Ruby
C::SpreadsheetExport::Order.to_invoices(orders, field_config, filename)
```

Where:

- `orders` is an array of C::Order::Sale objects.
- `field_config` is a field config (see above)
- `filename` is the filename to write to. This must be accessible and writeable.

#### Item Lists

Item Lists show an extremely simple list of items from the given orders. Ensure
that `item_fields` is set in the field config. If you want grouping, also ensure
that `group_field` and `static_fields` are set as necessary.

Item lists can be created as following:

```Ruby
C::SpreadsheetExport::Order.to_item_list(orders, field_config, filename)
```

Where:

- `orders` is an array of C::Order::Sale objects.
- `field_config` is a field config (see above). A default field config for item
  lists can be found at `C::SpreadsheetExport::Orders::DEFAULT_ITEM_CONFIG`.
- `filename` is the filename to write to. This must be accessible and writeable.

## Ebay Functions

### Ex-VAT Threshold on Import

Any product imported from eBay will have its price checked against the `ex_vat_threshold` variable set in `c.rb` / `commercity.rb`. If the price is less than `ex_vat_threshold`, the `tax_rate` will be set to 0 and the `with_tax` price will be set to this imported price.

If the product's price is equal to or greater than `ex_vat_threshold`, its `tax_rate` will be set (to probably 20%) and the `with_tax` price will be set to this imported a price.

For example, with a `ex_vat_threshold` of £500 (or 50000 pennies), a product with a price of £499 will have its `tax_rate` set to 0, and both its `with_tax` & `without_tax` prices set to £499. A product with a price of £500, will have a `tax_rate` set to 20% and its `with_tax` price will be £500 whilst its `without_tax` price will be £400.

This is configured by the `ex_vat` & `ex_vat_threshold` variables in `c.rb` / `commercity.rb`

### Syncing and revising recent listings

An eBay job exists called `process_recent_unsynced_listings` that grabs all listings published on eBay within the last day. It will create products locally for each of these listings (unless they already exist) with most of the listing information. Their SKU will initially be set to their eBay ItemID.

The job then calls another method which grabs all listings without a `last_sync_time`, i.e. any recently created listings, syncs them and updates any details the above task misses (such as setting an MPN and updating the SKU). Then, all of the listings are revised on eBay, pushing up information such as the shop wrap.

Finally, categories are created based on the eBay category for each product that has been imported and categorizations are also created for each product and their corresponding category.

### Shop Wrap

There is a resource for eBay shop wraps and each eBay channel have their own field for a shop wrap. The eBay channel specific shop wrap takes priority and this will be pushed to eBay. If an eBay channel does not have its own shop wrap set, it will check the resource and try to grab the first shop wrap and push that up. If an eBay channel has no shop wrap saved and there are no universal shop wraps saved, the description of the eBay channel/web channel/variant will be pushed up as raw html.

TL;DR: `eBay channel wrap > universal wrap > description`

### Product Questions and Answers

A product variant has many questions (customers asking for clarification on product details), which each have many answers from the seller.

Questions have an enumerated `source` field indicating where the question was asked, one of 'ebay', 'amazon' or 'web'.

The `get_questions` eBay job pulls all current product questions from eBay and associates them with the correct product variants, creating `C::Product::Question` records and updating those which already exist:

```Ruby
C::EbayJob.perform_now('get_questions')
# Product questions were pulled from eBay
```

The job does not process questions concerning products which do not exist in Commercity.

The eBay API does not support pulling the answers to questions, only whether or not a question has been answered. An answered question (indicated by the `answered` field) with no known answers is given a new answer marked as 'external', indicating that the question has been answered externally (such as on the eBay website), rather than from Commercity.

Questions can be answered from Commercity via the creation of a `C::Product::Answer` record. The `send_answer` eBay job is used to push this answer back to eBay:

```Ruby
@answer = @question.answers.create!(body: 'An answer to @question.')
C::EbayJob.perform_now('send_answer', @answer)
# @answer was pushed to eBay
```

By default, `send_answer` will not push to eBay unless the given answer has not already been sent, and belongs to a question asked on eBay (indicated by the answer's `sent` field, and the associated question's `source` field). However, providing the `force: true` option overrides this behaviour:

```Ruby
@answer = @question.answers.create!(body: 'An answer to @question.', sent: true)
C::EbayJob.perform_now('send_answer', @answer)
# @answer was not pushed to eBay
C::EbayJob.perform_now('send_answer', @answer, force: true)
# @answer was pushed to eBay
```

After being pushed successfully, the answer's `sent` field is set to true.

### Product Offers

EBay allows buyers to make an offer to the seller which is lower than the asking price. These are represented as `C::Order::Offer` records.

Like questions, offers have an enumerated `source` field indicating their origin.

Offers may be for multiple items, indicated by the `quantity` field. The monetized `price` field for an offer is per item, not total.

The `get_offers` eBay job pulls all pending (awaiting seller response) offers. Any existing offers have their status set to 'resolved', unless they are updated by the pull.

```Ruby
C::EbayJob.perform_now('get_offers')
# Pending offers were pulled from eBay
```

Currently, there is not support for responding to offers from within Commercity. They must be externally resolved from the product's offers page on the eBay website:

```Ruby
@offer = C::Product::Offer.first
puts "https://ofr.ebay.co.uk/offerapp/bo/showOffers/#{offer.variant.item_id}"
# Prints the url at which the offer can be responded to
```

## Payment Method Setup

### Worldpay Business Gateway

#### Terms

- _Merchant Interface_: The website to manage the settings of the Worldpay
  Business Gateway account.
  [Found here](https://secure.worldpay.com/sso/public/auth/login.html).

#### Commercity Settings

- `config.use_worldpay_bg`: Boolean, enables the Commercity integration.

#### Environment Variables

- ##### `WORLDPAY_BG_LIVE`

  _A control variable to set the site to live._

  If this variable is present, all links and transactions will be aimed at the
  live system. **Do not set the variable to `false` or a blank value for
  testing, it will still be considered present!**

- ##### `WORLDPAY_BG_INSTALLATION_ID`

  _The ID of the Worldpay Business Gateway to be used._

  **Example**: `'1235592'`

  A Worldpay Business Gateway can have many installations, whether it's one per
  currency, one per sub-business or one per type of payment method (web/card
  machine). Typically a 7-digit number. Include as string to avoid missing out
  any leading zeros.

- ##### `WORLDPAY_BG_SECRET`

  _The MD5 secret for transactions field._

  **Example**: `'Wheels&Exhausts&01493'`

  Allows for some slight verification, but not too much. Should be exactly the
  string set in the 'MD5 Secret for transactions' box on the Merchant Interface.
  Must be between 20 and 30 characters and contain at least one of each of the
  following:

  - Upper-case character
  - Lower-case character
  - Symbol
  - Number

- ##### `WORLDPAY_BG_RESPONSE_PASSWORD`

  _The password for barely checking the response validity._

  **Example**: `'aSimplePassword'`

  Allows for some slight verification, but not too much. Should be exactly the
  string set in the 'Payment Response' box on the Merchant Interface. There
  don't appear to be any particular limitations on content.

#### Setting up the Merchant Interface for Use

1. Log into the
   [Merchant Interface](https://secure.worldpay.com/sso/public/auth/login.html).

2. Click on 'Setup' in the sidebar

3. Click on 'Installations' in the main panel.

4. Click on the settings icon for the Integration Setup: TEST.

5. In the 'Payment Response URL' box, enter:
   `https://<DOMAIN_NAME>/cart/checkout/worldpay_bg_return`.

6. Tick the 'Payment Response enabled?' box.

7. In the 'Shopper Redirect URL' box, enter:
   `https://<DOMAIN_NAME>/cart/checkout/worldpay_bg_shopper_return`.
   (This isn't currently used, but it's good to have set up for when we figure
   out how to redirect).

8. In the 'Payment Response password' box, enter the value for
   WORLDPAY_BG_RESPONSE_PASSWORD.

9. In the 'MD5 secret for transactions' box, enter the value for
   WORLDPAY_BG_SECRET.

10. In the 'SignatureFields' box, enter: `instId:amount:currency:cartId`.

11. Click 'Save Changes'

Once a test transaction is made, the account should be activated for production
and the above steps repeated for the Integration Setup: PRODUCTION settings.
