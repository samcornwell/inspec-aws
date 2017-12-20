control "aws_s3_buckets bucket should exist" do
  describe aws_s3_buckets do
    it { should exist }
  end
end
