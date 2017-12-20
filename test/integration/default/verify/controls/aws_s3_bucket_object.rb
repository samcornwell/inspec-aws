fixtures = {}
[
  's3_bucket_name',
].each do |fixture_name|
  fixtures[fixture_name] = attribute(
    fixture_name,
    default: "default.#{fixture_name}",
    description: 'See ../build/s3.tf',
  )
end

describe aws_s3_bucket_object(name: fixtures['s3_bucket_name'], key: 'public-pic-authenticated.jpg') do
  it { should exist }
  it { should be_public }
  its('auth_users_permissions') { should cmp [] }
end
