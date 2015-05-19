# CREATOR : Ali Hassan Mirza
# This rake will be used to insert different api messages and codes in api_message document
#
desc "Add api messages for different types of errors"

task :generate_api_messages => :environment do
  begin
    Message.destroy_all
    puts "starting rake"
    Message.create(:status => "Ok",:code => "200",:detail=>"")
    Message.create(:status => "Created",:code => "201",:detail=>"")
    Message.create(:status => "Unauthorized",:code => "401",:detail=>"")
    Message.create(:status => "Not found",:code => "404",:detail=>"")
    Message.create(:status => "Forbidden",:code => "403",:detail=>"")
    Message.create(:status => "Account not activated",:code => "402",:detail=>"")
    Message.create(:status => "Device not approved yet",:code => "405",:detail=>"")
    Message.create(:status => "Device not registered",:code => "406",:detail=>"")
    Message.create(:status => "Device already registered",:code => "407",:detail=>"")
    Message.create(:status => "Connection established",:code => "408",:detail=>"")
    Message.create(:status => "Connection failed",:code => "409",:detail=>"")
    Message.create(:code=>"500",:status=>"Internal Server Error",:detail=>"")
    Message.create(:code=>"501",:status=>"Error",:detail=>"")
    Message.create(:code=>"580",:status=>"Device Unlinked",:detail=>"")
    Message.create(:code=>"581",:status=>"Incident Closed",:detail=>"")
    Message.create(:code=>"582",:status=>"Status time error",:detail=>"")
    Message.create(:code=>"505",:status=>"Not Supported",:detail=>"")
    puts "Rake finished"
  end
end