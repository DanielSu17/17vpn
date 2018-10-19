package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCheckDiff(t *testing.T) {
	cases := []struct {
		removed, added string
		expected       bool
	}{
		// no params
		{
			`"key1": "oldval1"
		     "key2": "oldval2"`,
			`"key1": "newval1"
		     "key2": "newval2"`,
			true,
		},
		// IOS same count
		{
			`"key1": "oldval1%1$@"
		     "key2": "oldval2"`,
			`"key1": "newval1%1$@"
		     "key2": "newval2"`,
			true,
		},
		// IOS new key
		{
			`"key1": "oldval1"`,
			`"key1": "newval1"
		     "key2": "newval2%1$@"`,
			true,
		},
		// IOS remove key
		{
			`"key1": "oldval1%1$@"
		     "key2": "newval2"`,
			`"key2": "newval2"`,
			true,
		},
		// IOS 2 params -> 1 param
		{
			`"key1": "oldval1%1$@,%2$@"`,
			`"key1": "newval1%1$@"`,
			false,
		},
		// IOS 1 param -> 2 params
		{
			`"key1": "newval1%1$@"`,
			`"key1": "oldval1%1$@,%2$@"`,
			false,
		},
		// Android same count
		{
			`"key1": "oldval1%1$s"
		     "key2": "oldval2"`,
			`"key1": "newval1%1$s"
		     "key2": "newval2"`,
			true,
		},
		// Android new key
		{
			`"key1": "oldval1"`,
			`"key1": "newval1"
		     "key2": "newval2%1$s"`,
			true,
		},
		// Android remove key
		{
			`"key1": "oldval1%1$s"
		     "key2": "newval2"`,
			`"key2": "newval2"`,
			true,
		},
		// Android 2 params -> 1 param
		{
			`"key1": "oldval1%1$s,%2$s"`,
			`"key1": "newval1%1$s"`,
			false,
		},
		// Android 1 param -> 2 params
		{
			`"key1": "newval1%1$s"`,
			`"key1": "oldval1%1$s,%2$s"`,
			false,
		},
		// Backend same count
		{
			`"key1": "oldval1$1"
		     "key2": "oldval2"`,
			`"key1": "newval1$1"
		     "key2": "newval2"`,
			true,
		},
		// Backend new key
		{
			`"key1": "oldval1"`,
			`"key1": "newval1"
		     "key2": "newval2$1"`,
			true,
		},
		// Backend remove key
		{
			`"key1": "oldval1$1"
		     "key2": "newval2"`,
			`"key2": "newval2"`,
			true,
		},
		// Backend 2 params -> 1 param
		{
			`"key1": "oldval1$1,$2"`,
			`"key1": "newval1$1"`,
			false,
		},
		// Backend 1 param -> 2 params
		{
			`"key1": "newval1$1"`,
			`"key1": "oldval1$1,$2"`,
			false,
		},
	}
	for _, c := range cases {
		o := checkDiff(c.removed, c.added)
		assert.Equal(t, c.expected, o)
	}
}
