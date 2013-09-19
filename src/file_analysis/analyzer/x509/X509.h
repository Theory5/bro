#ifndef FILE_ANALYSIS_X509_H
#define FILE_ANALYSIS_X509_H

#include <string>

#include "Val.h"
#include "../File.h"
#include "Analyzer.h"

#include <openssl/x509.h>
#include <openssl/asn1.h>

namespace file_analysis {

class X509 : public file_analysis::Analyzer {
public:
	//~X509();

	static file_analysis::Analyzer* Instantiate(RecordVal* args, File* file)
		{ return new X509(args, file); }

	virtual bool DeliverStream(const u_char* data, uint64 len);
	virtual bool Undelivered(uint64 offset, uint64 len);	
	virtual bool EndOfFile();

protected:
	X509(RecordVal* args, File* file);

private:
	static double get_time_from_asn1(const ASN1_TIME * atime);
	static StringVal* key_curve(EVP_PKEY *key);
	static unsigned int key_length(EVP_PKEY *key);

	void ParseCertificate(::X509* ssl_cert);
	void ParseExtension(X509_EXTENSION* ex);
	void ParseBasicConstraints(X509_EXTENSION* ex);
	void ParseSAN(X509_EXTENSION* ex);

	std::string cert_data;
};

}

#endif
