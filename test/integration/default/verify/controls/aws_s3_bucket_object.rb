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
  bucket_object = aws_s3_bucket_object(
    bucket_name: fixtures['s3_bucket_auth_name'],
    object_key: fixtures['s3_bucket_object_private_name']
  )
  bucket = aws_s3_bucket(
    bucket_name: fixtures['s3_bucket_auth_name'],
  )

  describe bucket_object do
    it { should exist }
  end

  describe "Bucket Policy: Empty policy on auth" do
    subject do
      bucket_object.bucket_policy
    end
    it { should be_empty }
  end

  describe bucket do
    it { should have_acl_public_read }
    it { should_not have_acl_public_write }
  end

  bucket.bucket_objects.each do |object|
    describe aws_s3_bucket_object(
      bucket_name: bucket.bucket_name,
      object_key: object.key
    ) do
      it { should have_acl_public_read }
      it { should_not have_acl_public_write }
    end
  end

  # describe "Bucket Object #{bucket_object.to_s} ACL: Owner with FULL_CONTROL" do
  #   subject do
  #     bucket_object.object_acl.select do |g|
  #       g.grantee.type == 'CanonicalUser' &&
  #       g.grantee.id == bucket_object.object_owner.id &&
  #       g.permission == 'FULL_CONTROL'
  #     end
  #   end
  #   it { should_not be_empty }
  # end

  # describe "Object Bucket #{bucket_object.to_s} ACL: Number of grantees with more than READ" do
  #   subject do
  #     bucket_object.object_acl.select do |g|
  #       g.permission != 'READ'
  #     end
  #   end
  # end
end
