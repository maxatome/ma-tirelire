# $Id: doaddition.pl,v 1.3 2004/05/28 02:32:10 arpruss Exp $
#    Copyright (c) 2004, Alexander R. Pruss
#    All rights reserved.
#
#    Redistribution and use in source and binary forms, with or without modification,
#    are permitted provided that the following conditions are met:
#
#        Redistributions of source code must retain the above copyright notice, this
#        list of conditions and the following disclaimer.
#
#        Redistributions in binary form must reproduce the above copyright notice, this
#        list of conditions and the following disclaimer in the documentation and/or
#        other materials provided with the distribution.
#
#        Neither the name of the PalmResize Project nor the names of its
#        contributors may be used to endorse or promote products derived from this
#        software without specific prior written permission.
#
#    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
#    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
#    ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#$ver = `grep ^VERSION PalmBible.rcp | awk -F\\\" '{print \$2}'`;
#chop($ver);

while(<>) {
    s/\@backslash\@$/\\/g;
    s/0.99/$ver/g;
    $inputLine = $_;
    if ( /^WORDLIST / ) {
        $inWordList = 1;
    }
    elsif ( /^BEGIN/ && $inWordList ) {
        $inListBody = 1;
    }
    elsif ( /^END/ && $inListBody ) {
        $inWordList = 0;
        $inListBody = 0;
    }
    elsif ( $inListBody ) {
        s/(0[xX][0-9a-fA-F]+)/hex($1)/eg;
        while ( s/([0-9]+)\s*\+\s*([0-9]+)/$1+$2/eg ) {};
        if ( /[^\f\t\n\r 0-9]/ ) {
            die "Error in: $_";
        }
    }
    print;
}

