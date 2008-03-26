require File.dirname(__FILE__) + '/helper'

context "Static files (by default)" do

  setup do
    Sinatra.application = nil
    Sinatra.application.options.public = File.dirname(__FILE__) + '/public'
  end

  specify "are served from root/public" do
    get_it '/foo.xml'
    should.be.ok
    headers['Content-Length'].should.equal '12'
    headers['Content-Type'].should.equal 'application/xml'
    body.should.equal "<foo></foo>\n"
  end

  specify "are not served when verb is not GET or HEAD" do
    post_it '/foo.xml'
    # these should actually be giving back a 405 Method Not Allowed but that
    # complicates the routing logic quite a bit.
    should.be.not_found
    status.should.equal 404
  end

  specify "are served when verb is HEAD but missing a body" do
    head_it '/foo.xml'
    should.be.ok
    headers['Content-Length'].should.equal '12'
    headers['Content-Type'].should.equal 'application/xml'
    body.should.equal ""
  end

  # static files override dynamic/internal events and ...
  specify "are served when conflicting events exists" do
    get '/foo.xml' do
      'this is not foo.xml!'
    end
    get_it '/foo.xml'
    should.be.ok
    body.should.equal "<foo></foo>\n"
  end

  specify "are irrelevant when request_method is not GET/HEAD" do
    put '/foo.xml' do
      'putted!'
    end
    put_it '/foo.xml'
    should.be.ok
    body.should.equal 'putted!'

    get_it '/foo.xml'
    should.be.ok
    body.should.equal "<foo></foo>\n"
  end

  specify "include a Last-Modified header" do
    last_modified = File.mtime(Sinatra.application.options.public + '/foo.xml')
    get_it('/foo.xml')
    should.be.ok
    body.should.not.be.empty
    headers['Last-Modified'].should.equal last_modified.httpdate
  end

  specify "are not served when If-Modified-Since matches" do
    last_modified = File.mtime(Sinatra.application.options.public + '/foo.xml')
    @request = Rack::MockRequest.new(Sinatra.application)
    @response = @request.get('/foo.xml', 'HTTP_IF_MODIFIED_SINCE' => last_modified.httpdate)
    status.should.equal 304
    body.should.be.empty
  end

end

context "SendData" do
  
  setup do
    Sinatra.application = nil
  end

  specify "should send the data with options" do
    get '/' do
      send_data 'asdf', :status => 500
    end
  
    get_it '/'
  
    should.be.server_error
    body.should.equal 'asdf'
  end
  
end
