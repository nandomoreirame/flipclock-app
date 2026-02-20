package main

import (
	_ "embed"

	"fyne.io/fyne/v2"
)

//go:embed fonts/BebasNeue-Regular.ttf
var bebasNeueTTF []byte

var fontBold = fyne.NewStaticResource("BebasNeue-Regular.ttf", bebasNeueTTF)
