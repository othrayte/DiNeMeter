package dinemeter.master.frontend;

import dinemeter.DataList;
import dinemeter.DataRecord;
import js.Lib;
import js.DomCanvas;

import easelhx.display.Stage;
import easelhx.display.Shape;

using Lambda;
using dinemeter.DataRecord;


/**
 *  This file is part of DiNeMeterMaster.
 *
 *  DiNeMeterMaster is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or any later version.
 *
 *  DiNeMeterMaster is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with DiNeMeterMaster.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author othrayte
 */

class UsageGraph {
	var canvas:DomCanvas;
	var stage:Stage;
	var bg:Shape;
	var downLines:Hash<PlotLine>;
	var upLines:Hash<PlotLine>;
	var uDownLines:Hash<PlotLine>;
	var uUpLines:Hash<PlotLine>;
    
    var colours:Array<Int>;
    
	var width:Float;
	var height:Float;
	
    var graphWidth:Float;
	var graphHeight:Float;
	
	var dScale:Float;
	var uScale:Float;
	
	public function new(id:String) {
		canvas = cast Lib.document.getElementById(id);
		stage = new Stage(canvas);
		
        colours = [0xCD1E14, 0x12D6EB, 0x4BCE13, 0xF8F103, 0xC94E18, 0x1879E4, 0x82C61C, 0xF0DF0B, 0xCD7514, 0x1279EB, 0x24BD30, 0xFBC900];
        
        downLines = new Hash();
        upLines = new Hash();
        uDownLines = new Hash();
        uUpLines = new Hash();
        
		width = canvas.width;
		height = canvas.height;
        
        graphWidth = width - 100;
        graphHeight = height - 40;
		
		bg = new Shape();
		
		stage.addChild(bg);
		
		stage.tick();
	}
    
    public function setup(usernames:Array<String>) {
        for (username in usernames) {
            var dPL = new PlotLine(colours.shift(), graphWidth, graphHeight, "down");
            downLines.set(username, dPL);
            dPL.x = 100;
            stage.addChild(dPL);
            var uPL = new PlotLine(colours.shift(), graphWidth, graphHeight, "up");
            upLines.set(username, uPL);
            uPL.x = 100;
            stage.addChild(uPL);
            var uDPL = new PlotLine(colours.shift(), graphWidth, graphHeight, "uDown");
            uDownLines.set(username, uDPL);
            uDPL.x = 100;
            stage.addChild(uDPL);
            var uUPL = new PlotLine(colours.shift(), graphWidth, graphHeight, "uUp");
            uUpLines.set(username, uUPL);
            uUPL.x = 100;
            stage.addChild(uUPL);
        }
    }
    
	public function display(data:Hash<DataList<DataRecord>>, start:Int, now:Int , end:Int) {
        if ((now - start) < 3 * 24 * 60 * 60) {
            end = 3 * 24 * 60 * 60;
        } else {
            end = now;
        }
		var res:Int = 3*60*60;
        var hScale:Float = graphWidth / ((end-start)/res);
        var vScale:Float = (res * 2 * 1024 * 1024)/hScale;
        bg.graphics.clear();
        
        /*bg.graphics.beginFill("white");
        bg.graphics.drawRect(100,0,graphWidth, graphHeight);
        bg.graphics.endFill();*/
        
        for (username in data.keys()) {
            var dl = data.get(username);
            var vals:DataList<DataRecord> = dl.refactor(start, now+res, res);
            var sorted:Array<DataRecord> = new Array();
            for (item in vals) {
                sorted[Math.round((item.start - start) / res)] = item;
            }
            for (i in 0 ... sorted.length) {
                if (sorted[i] == null) sorted[i] = new DataRecord();
            }
            if (downLines.exists(username)) downLines.get(username).display(sorted, start, now, end, vScale, hScale);
            if (upLines.exists(username)) upLines.get(username).display(sorted, start, now, end, vScale, hScale);
            if (uDownLines.exists(username)) uDownLines.get(username).display(sorted, start, now, end, vScale, hScale);
            if (uUpLines.exists(username)) uUpLines.get(username).display(sorted, start, now, end, vScale, hScale);
        }
		
		stage.tick();
	}
	
}