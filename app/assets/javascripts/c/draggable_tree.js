var $current_container, $ghost, $ghostBottom, $ghostMid, $ghostTop, $sibling_container, beginDrag, checkLessNesting, checkMoreNesting, checkNeedToMove, checkSiblings, collapse, convertYtoElem, endDrag, getGenericTree, moveDrag, newYPos, requestedYPos, uncollapse, updateGenericTree;
var $current_moving = null;
var $_ghost = null;
var $container = null;

$(window).on('load page:load', function() {
    $container = $('.draggable_tree_list_container');
    return $('[data-draggable]').each(function() {
        return $(this).on('mousedown', $(this).data('draggable'), beginDrag);
    });
});

beginDrag = function(e) {
    var cur_height;
    $(window).on('mouseup', endDrag);
    $(window).on('mousemove', moveDrag);
    $current_moving = $(e.delegateTarget);
    collapse();
    console.log($current_moving.find('input[type=check_box].hide_children'));
    cur_height = $current_moving.height();
    $current_moving.addClass('floating');
    return $ghost().css({
        height: cur_height
    }).insertAfter($current_moving);
};

moveDrag = function(e) {
    checkNeedToMove(e);
    return $current_moving.css({
        top: newYPos(e)
    });
};

endDrag = function() {
    $(window).off('mouseup', endDrag);
    $(window).off('mousemove', moveDrag);
    $current_moving.insertAfter($ghost());
    $current_moving.removeClass('floating');
    $current_moving.removeAttr('style');
    uncollapse();
    $ghost().detach();
    return updateGenericTree();
};

collapse = function() {
    var $check;
    $check = $current_moving.find('input[type=checkbox].hide_children:first');
    $check.data('before_drag_collapse_state', $check.prop('checked'));
    return $check.prop('checked', true);
};

uncollapse = function() {
    var $check, before_state;
    $check = $current_moving.find('input[type=checkbox].hide_children').first();
    before_state = $check.data('before_drag_collapse_state');
    $check.prop('checked', before_state);
    return $check.data('before_drag_collapse_state', null);
};

convertYtoElem = function(y, elem) {
    return y - $(elem).offset().top;
};

requestedYPos = function(e) {
    return convertYtoElem(e.pageY, $sibling_container()) - $current_moving.height() / 2;
};

newYPos = function(e) {
    var high_y, low_y, y;
    low_y = 0;
    y = requestedYPos(e);
    high_y = $sibling_container().height() - $current_moving.height();
    if (y < low_y) {
        return low_y;
    }
    if (y > high_y) {
        return high_y;
    }
    return y;
};

checkNeedToMove = function(e) {
    var moved;
    moved = checkMoreNesting(e);
    if (!moved){
        moved = checkLessNesting(e)
    }
    if (moved) {
        return checkNeedToMove(e);
    }
};

checkMoreNesting = function(e) {
    var $next, $nextChildren, $prev, $prevChildren, next_y, prev_y, y;
    $prev = $ghost().prevAll('.draggable_tree_container:not(.floating):first');
    $next = $ghost().nextAll('.draggable_tree_container:first');
    $nextChildren = $next.find('.draggable_tree_children:first');
    $prevChildren = $prev.find('.draggable_tree_children:first');
    y = convertYtoElem(e.pageY, $sibling_container());
    if ($nextChildren.length > 0) {
        next_y = convertYtoElem($nextChildren.offset().top, $sibling_container());
        next_y -= $current_moving.height() / 4;
        if (y > next_y) {
            $nextChildren.prepend($ghost());
            return true;
        }
    }
    if ($prevChildren.length > 0) {
        prev_y = convertYtoElem($prevChildren.offset().top + $prevChildren.height(), $sibling_container());
        prev_y += 20;
        if (y < prev_y) {
            $prevChildren.prepend($ghost());
            return true;
        }
    }
    return false;
};

checkLessNesting = function(e) {
    var containerBottom, containerTop, y;
    if ($current_container().length === 0) {
        return;
    }
    y = convertYtoElem(e.pageY, $current_container());
    containerTop = 0;
    containerBottom = $current_container().height();
    if (y < containerTop + $current_moving.height()) {
        $ghost().insertBefore($current_container());
        $current_moving.insertBefore($ghost());
        return true;
    }
    if (y > containerBottom) {
        $ghost().insertAfter($current_container());
        $current_moving.insertBefore($ghost());
        return true;
    }
    return false;
};

checkSiblings = function(e) {
    var $next, $prev;
    $prev = $ghost().prevAll('.draggable_tree_container:not(.floating):first');
    $next = $ghost().nextAll('.draggable_tree_container:first');
    if ($ghostBottom() + ($next.height() / 2) < requestedYPos(e) + $current_moving.height() / 2) {
        return $ghost().insertAfter($next);
    } else if ($ghostTop() - ($prev.height() / 2) > requestedYPos(e) + $current_moving.height() / 2) {
        return $ghost().insertBefore($prev);
    }
};

$ghost = function() {
    if ($_ghost === null) {
        $_ghost = $('<div data-ghost></div>');
        console.log("CRETING");
    }
    window.x = $_ghost;
    return $_ghost;
};

$ghostTop = function() {
    return $ghost().position().top;
};

$ghostMid = function() {
    return $ghost().position().top + $ghost().height() / 2;
};

$ghostBottom = function() {
    return $ghost().position().top + $ghost().height();
};

$sibling_container = function() {
    return $current_moving.parent().closest('.draggable_tree_children');
};

$current_container = function() {
    return $ghost().parent().closest('.draggable_tree_container');
};

updateGenericTree = function($elem, ret) {
    var genericTree;
    if (ret === null) {
        ret = false;
    }
    genericTree = getGenericTree($container);
    console.log(window.xxx = genericTree);
    return $.ajax({
        url: $container.data('reorder-url'),
        method: 'patch',
        data: {
            order: xxx
        },
        complete: function(resp) {
            return console.log(resp);
        }
    });
};

getGenericTree = function() {
    var draggable_tree_descendants;
    draggable_tree_descendants = {};
    $container.find('.draggable_tree_container').each(function(i, elem) {
        var $elem, child_ids, e, id, id_field;
        $elem = $(elem);
        id_field = $elem.data('draggable-tree-id-field');
        id = $elem.data(id_field);
        child_ids = (function() {
            var j, len, ref, results;
            ref = $elem.children('.draggable_tree_children').children('.draggable_tree_container');
            results = [];
            for (j = 0, len = ref.length; j < len; j++) {
                e = ref[j];
                results.push($(e).data(id_field));
            }
            return results;
        }());
        draggable_tree_descendants[id] = {
            child_ids: child_ids,
            weight: $elem.index() + 1
        };
    });
    return draggable_tree_descendants;
};
