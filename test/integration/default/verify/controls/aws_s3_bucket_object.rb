fixtures = {}
[
  's3_bucket_auth_name',
  's3_bucket_object_private_name',
].each do |fixture_name|
  fixtures[fixture_name] = attribute(
    fixture_name,
    default: "default.#{fixture_name}",
    description: 'See ../build/s3.tf',
  )
end

control "aws_s3_bucket_object recall" do
  bucket_object = aws_s3_bucket_object(bucket_name: fixtures['s3_bucket_auth_name'], object_key: fixtures['s3_bucket_object_private_name'])

  describe bucket_object do
    it { should exist }
  end

  describe "Object Bucket Policy: Empty policy on auth" do
    subject do
      bucket_object.bucket_policy
    end
    it { should be_empty }
  end
end
