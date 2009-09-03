package AcoreX::Inquiry;

use strict;
use warnings;

1;

__END__

=head1 NAME

AcoreX::Inquiry

=head1 DISPATCH TABLE

  connect "inquiry/:action",   to extra "Inquiry::Root";

  connect "somewhere/:action", to extra "Inquiry::Root" => "",
      args => { location => "somewhere" };

=head1 CONFIG

 include_path:
   - path/to/assets/inquiry/templates    # basic sample
 "AcoreX::Inquiry":
    inquiry:
      document_class:
      rules:
        name: 
          - NOT_NULL
        body:
          - NOT_NULL
      messages:
       name.not_null: お名前を入力してください。
       body.not_null: お問い合わせ内容を入力してください。
    somewhere:
      document_class: MyInquiryDocument

