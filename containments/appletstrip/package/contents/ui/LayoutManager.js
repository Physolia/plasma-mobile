/*
 *   Copyright 2011 Marco Martin <mart@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

var items = new Array()

function insertAt(item, index)
{
    if (index < 0 || index > (items.length-1)) {
        items.push(item)
        item.parent = appletsRow
        return
    }

    //reinsert at old position? do nothing
    if (item == items[index]) {
        return;
    }

    var oldChildren = Array()
    for (var i = index; i < items.length; ++i) {
        oldChildren[oldChildren.length] = items[i]
        print(oldChildren[oldChildren.length-1])
    }

    item.parent = main
    for (var i = 0; i < oldChildren.length; ++i) {
        oldChildren[i].parent = main
    }
    item.parent = appletsRow
    for (var i = 0; i < oldChildren.length; ++i) {
        oldChildren[i].parent = appletsRow
    }
}

function remove(item)
{
    var index = 0
    for (var i = 0; i < items.length; ++i) {
        if (items[i] == item) {
            item.parent = main
            index = i
            break
        }
    }
    items.splice(index, 1)
}
