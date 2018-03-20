# Scruber-mongo

This gem provides Mongo support for Scruber

## Installation

1. Add this line to your application's Gemfile:

```ruby
gem 'scruber-mongo'
```

2. And then execute:

    $ bundle

3. Install gem

    $ scruber generate mongo:install

This gem provides Queue driver, Output driver and FetcherAgent driver for mongo.

## Sample scraper

```ruby
Scruber.run do
  get "http://example.abc/product"
  
  parse :html do |page, doc|
    id = mongo_out_product title: doc.at('title').text

    get_reviews URI.join(page.url, doc.at('a.review_link').attr('href')).to_s, product_id: id
  end

  parse_reviews :html do |page,doc|
    product = mongo_find_product page.options[:product_id]

    product[:reviews] = doc.search('.review').map{|r| {author: r.at('.author').text, text: r.at('.text').text } }

    mongo_out_product product
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/scruber/scruber-mongo.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
