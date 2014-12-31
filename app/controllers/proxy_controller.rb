require 'net/https'
require 'openssl'

# This controller makes RESTful API calls and caches them. If a timeout is exceeded, the call is made again.  
class ProxyController < ApplicationController
  
  # Expire cache after 10 minutes
  @@timeout = 600
  
  # On the main index page, get all previous caches. Display them for easy calls
  def index
    @caches = JsonCache.all
  end
  
  # This is a GET API call. This takes an input URL, checks to see if a cached record exists, and if not, adds on an API key and makes the call.
  def get
    # Get all caches
    @caches = JsonCache.all
    
    # Get URL and make full URL including API key
    @url = params[:url]
    @fullUrl = @url+"?apiKey="+ENV["API_KEY"]
    
    # Check if timeout was input, if not, fallback on default
    @timeout = params[:timeout]
    if (@timeout.empty?)
      @timeout = @@timeout
    end
    
    # Check first cache instance with the same input URL
    @cache = JsonCache.where(url: @url).first
    
    # If no cache was found, we'll make the API request
    if (@cache.nil?)
      log("cache empty")
      
      # Make API call
      @response = HTTParty.get(@fullUrl)
      
      # cache the response
      @cache = JsonCache.new(url: @url,json: @response)
      
      # Save the cache to the db
      @cache.save
    else
      # if a cache was found, check when it was updated. Subtract "now" from the cache's "updated_at"
      # if it exceeds the timeout, make a call again
      if Time.zone.now - @cache.updated_at >= @timeout.to_f
        log("Timeout of " + (Time.zone.now - @cache.updated_at).inspect + " exceeded limit: "+@timeout)
        
        # Make the call
        @response = HTTParty.get(@fullUrl)
        
        # Update the caches json string
        @cache.json = @response
        
        # Update the timestamp
        @cache.updated_at = Time.zone.now
        
        # Save to database
        @cache.save
      else
        log("Using cache of age: "+(Time.zone.now - @cache.updated_at).inspect + " seconds")
      end 
      
      # Set our cache's json
      @response = @cache.json
      
    end
  end
  
  # Simple log function. If log var is nil, create new one. 
  def log(text)
    if (@log.nil?)
      @log = text
    else
      @log += text  
    end
  end
  
end
